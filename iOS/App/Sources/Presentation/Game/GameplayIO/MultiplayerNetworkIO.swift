//
//  MultiplayerNetworkIO.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/20/26.
//

import Foundation
import Games
import NetworkKit

// MARK: - Multiplayer Network IO

@MainActor
final class MultiplayerNetworkIO {
    private let localPlayerID: UUID
    private let otherPlayerIDs: [UUID]
    private unowned let gameplayManager: GameplayManager
    private let inputProvider: FaceTrackingGameInputProvider
    private var networkSessionManager: NetworkSessionManaging

    private let jsonDecoder = JSONDecoder()

    private var peerName: String?

    private var remoteSendTask: Task<Void, Never>?
    private var movementSendAccumulator: TimeInterval = 0

    /// 이동 스냅샷 전송 주기(Hz). 15~20Hz
    private let movementSendInterval: TimeInterval = 1.0 / 15.0

    /// 움직임 변화가 작으면 전송 생략(네트워크/지터 최적화)
    private let movementSendThreshold: Double = 0.02

    private var lastSentMoveX: Double = 0
    private var pendingLocalMoveX: Double = 0

    // --- Receive + interpolation ---
    private var remoteTargetMoveX: Double = 0
    private var remoteSmoothedMoveX: Double = 0

    /// 원격 스냅샷이 끊겼을 때 멈추기 위한 liveness
    private var lastRemoteReceivedAt: TimeInterval = 0
    private var didForceStopRemote: Bool = false

    /// 지터를 줄이기 위한 smoothing 상수(작을수록 반응이 빠름)
    private let remoteSmoothingTimeConstant: TimeInterval = 0.08

    /// 이 시간 이상 원격 수신이 없으면 moveX=0 강제 적용
    private let remoteFreezeAfter: TimeInterval = 0.8

    init(
        localPlayerID: UUID,
        otherPlayerIDs: [UUID],
        gameplayManager: GameplayManager,
        inputProvider: FaceTrackingGameInputProvider,
        networkSessionManager: NetworkSessionManaging
    ) {
        self.localPlayerID = localPlayerID
        self.otherPlayerIDs = otherPlayerIDs
        self.gameplayManager = gameplayManager
        self.inputProvider = inputProvider
        self.networkSessionManager = networkSessionManager
    }

    func bind(peerName: String) {
        self.peerName = peerName

        // reset liveness so we don't freeze immediately
        lastRemoteReceivedAt = Date().timeIntervalSince1970
        didForceStopRemote = false

        installReceiveHandler()
        startForwardingLocalInput()
        installLocalJumpTriggeredSender()
        installLocalRespawnConfirmedSender()
    }

    func unbind() {
        peerName = nil

        remoteSendTask?.cancel()
        remoteSendTask = nil

        gameplayManager.onJumpTriggered = nil
        networkSessionManager.onInputReceived = nil
    }

    /// gameplayManager.update(deltaTime:)와 동일 틱에 실행되는 네트워크 처리
    func tick(deltaTime: TimeInterval) {
        guard peerName != nil else { return }
        sendMovementSnapshotIfNeeded(deltaTime: deltaTime)
        updateRemoteInterpolation(deltaTime: deltaTime)
    }

    // MARK: - Receive

    private func installReceiveHandler() {
        networkSessionManager.onInputReceived = { [weak self] sender, payload in
            guard let self else { return }

            Task { @MainActor in
                guard let peerName = self.peerName, sender == peerName else { return }
                guard let remotePlayerID = self.otherPlayerIDs.first else { return }

                guard let dto = try? self.jsonDecoder.decode(NetworkGameInputDTO.self, from: payload) else {
                    print("[NET][RECV] decode failed from \(sender)")
                    return
                }

                switch dto.kind {
                case .horizontal:
                    let x = Double(dto.x ?? 0)
                    self.lastRemoteReceivedAt = Date().timeIntervalSince1970
                    self.didForceStopRemote = false
                    self.remoteTargetMoveX = x

                case .jumpTriggered:
                    // 확정 이벤트: 검증 없이 즉시 적용
                    self.gameplayManager.applyJumpTriggered(for: remotePlayerID)
                    
                case .respawnRequested:
                    guard let raw = dto.reason,
                          let x = dto.respawnX,
                          let y = dto.respawnY,
                          let reason = self.decodeRespawnReason(raw) else {
                        print("[NET][RECV] respawnRequested decode failed from \(sender)")
                        return
                    }

                    let pos = RespawnPosition(x: x, y: y)
                    self.gameplayManager.applyRespawnRequested(reason, position: pos, for: remotePlayerID)
                }
            }
        }
    }
    
    private func installLocalRespawnConfirmedSender() {
        gameplayManager.onRespawnConfirmed = { [weak self] playerID, reason, position in
            guard let self else { return }
            guard playerID == self.localPlayerID else { return }
            guard let peerName = self.peerName else { return }

            let dto = NetworkGameInputDTO.respawnRequested(
                reason: self.encodeRespawnReason(reason),
                x: position.x,
                y: position.y
            )
            self.sendDTO(dto, to: peerName)
        }
    }
    
    private func encodeRespawnReason(_ reason: RespawnReason) -> Int {
        switch reason { case .fell: return 0; case .hitMonster: return 1 }
    }
    
    private func decodeRespawnReason(_ raw: Int) -> RespawnReason? {
        switch raw { case 0: return .fell; case 1: return .hitMonster; default: return nil }
    }

    // MARK: - Send (input -> cache)

    private func startForwardingLocalInput() {
        remoteSendTask?.cancel()
        remoteSendTask = Task { [weak self] in
            guard let self else { return }

            let stream = await self.inputProvider.events()
            for await event in stream {
                if Task.isCancelled { break }

                switch event {
                case .horizontal(let x):
                    self.pendingLocalMoveX = x
                case .jump:
                    // 점프는 tryJump 검증 통과 시 onJumpTriggered에서만 전송
                    break
                }
            }
        }
    }

    private func installLocalJumpTriggeredSender() {
        gameplayManager.onJumpTriggered = { [weak self] playerID in
            guard let self else { return }
            guard playerID == self.localPlayerID else { return }
            guard let peerName = self.peerName else { return }
            self.sendDTO(.jumpTriggered, to: peerName)
        }
    }

    // MARK: - Tick send + smoothing

    private func sendMovementSnapshotIfNeeded(deltaTime: TimeInterval) {
        guard let peerName = peerName else { return }

        movementSendAccumulator += deltaTime
        guard movementSendAccumulator >= movementSendInterval else { return }
        movementSendAccumulator -= movementSendInterval

        // 스냅샷 소스는 "현재 캐릭터 상태" 기반이 더 일관적(입력 지터 방지)
        let currentMoveX = gameplayManager.state.characters[localPlayerID]?.moveX ?? pendingLocalMoveX

        // 임계치 이하 변화면 전송 생략
        guard abs(currentMoveX - lastSentMoveX) >= movementSendThreshold else { return }

        // 간단 quantize(페이로드 안정화)
        let quantized = (currentMoveX * 100).rounded() / 100
        lastSentMoveX = quantized

        sendDTO(.horizontal(quantized), to: peerName)
    }

    private func updateRemoteInterpolation(deltaTime: TimeInterval) {
        guard let remotePlayerID = otherPlayerIDs.first else { return }

        // liveness: 일정 시간 수신이 없으면 안전하게 멈추기
        let now = Date().timeIntervalSince1970
        if (now - lastRemoteReceivedAt) > remoteFreezeAfter, didForceStopRemote == false {
            didForceStopRemote = true
            remoteTargetMoveX = 0
        }

        // exponential smoothing: alpha = 1 - exp(-dt / tau)
        let tau = max(remoteSmoothingTimeConstant, 0.001)
        let alpha = 1.0 - exp(-deltaTime / tau)
        remoteSmoothedMoveX = remoteSmoothedMoveX + (remoteTargetMoveX - remoteSmoothedMoveX) * alpha
        gameplayManager.updateMoveX(remoteSmoothedMoveX, for: remotePlayerID)
    }

    private func sendDTO(_ dto: NetworkGameInputDTO, to peerName: String) {
        do {
            networkSessionManager.sendInput(dto, to: peerName)
        } catch {
            print("[NET][SEND] encode failed: \(error)")
        }
    }
}
