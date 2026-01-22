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

actor MultiplayerNetworkIO {
    private let localPlayerID: UUID
    private let otherPlayerIDs: [UUID]
    private let gameplayManager: GameplayManager
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
    private var timeSinceLastMovementSend: TimeInterval = 0
    /// 동일 값 유지 시에도 liveness 보장을 위한 keep-alive 주기
    private let movementKeepAliveInterval: TimeInterval = 0.4
    
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

    // MARK: - Public entrypoints (non-async friendly)

    nonisolated func bind(peerName: String) {
        Task { await self.bindAsync(peerName: peerName) }
    }

    nonisolated func unbind() {
        Task { await self.unbindAsync() }
    }

    /// gameplayManager.update(deltaTime:)와 동일 틱에 실행되는 네트워크 처리
    /// `SKScene.update`는 동기(sync)로 호출되기 때문에, 여기서 바로 `await`를 사용할 수 없어
    ///  실제 작업을 `Task`로 감싸 actor 큐에 등록(enqueue)하여 비동기로 처리합니다.
    nonisolated func tick(deltaTime: TimeInterval) {
        Task { await self.tickAsync(deltaTime: deltaTime) }
    }

    // MARK: - Actor-isolated implementations

    private func bindAsync(peerName: String) async {
        self.peerName = peerName

        resetTransientState()

        await installReceiveHandler()
        await startForwardingLocalInput()
        await installLocalJumpTriggeredSender()
        await installLocalRespawnConfirmedSender()
    }
    
    private func resetTransientState() {
        movementSendAccumulator = 0
        timeSinceLastMovementSend = 0
        lastSentMoveX = 0
        pendingLocalMoveX = 0
        remoteTargetMoveX = 0
        remoteSmoothedMoveX = 0
        lastRemoteReceivedAt = Date().timeIntervalSince1970
        didForceStopRemote = false
    }

    private func unbindAsync() async {
        peerName = nil

        remoteSendTask?.cancel()
        remoteSendTask = nil

        await MainActor.run {
            self.gameplayManager.onJumpTriggered = nil
            self.gameplayManager.onRespawnConfirmed = nil
        }
        networkSessionManager.onInputReceived = nil
    }

    private func tickAsync(deltaTime: TimeInterval) async {
        guard peerName != nil else { return }
        await sendMovementSnapshotIfNeeded(deltaTime: deltaTime)
        await updateRemoteInterpolation(deltaTime: deltaTime)
    }

    // MARK: - Receive

    private func installReceiveHandler() async {
        networkSessionManager.onInputReceived = { [weak self] sender, payload in
            guard let self else { return }
            Task { await self.handleReceivedInput(sender: sender, payload: payload) }
        }
    }

    private func handleReceivedInput(sender: String, payload: Data) async {
        guard let peerName = self.peerName, sender == peerName else { return }
        guard let remotePlayerID = self.otherPlayerIDs.first else { return }

        guard let dto = try? self.jsonDecoder.decode(NetworkGameInputDTO.self, from: payload) else {
            return
        }

        switch dto.kind {
        case .horizontal:
            let x = Double(dto.x ?? 0)
            self.lastRemoteReceivedAt = Date().timeIntervalSince1970
            self.didForceStopRemote = false
            self.remoteTargetMoveX = x
        case .jumpTriggered:
            await MainActor.run {
                self.gameplayManager.applyJumpTriggered(for: remotePlayerID)
            }
        case .respawnRequested:
            guard let raw = dto.reason,
                  let x = dto.respawnX,
                  let y = dto.respawnY,
                  let reason = self.decodeRespawnReason(raw) else {
                return
            }
            let pos = RespawnPosition(x: x, y: y)
            await MainActor.run {
                self.gameplayManager.applyRespawnRequested(reason, position: pos, for: remotePlayerID)
            }
        }
    }
    
    private func installLocalRespawnConfirmedSender() async {
        await MainActor.run {
            self.gameplayManager.onRespawnConfirmed = { [weak self] playerID, reason, position in
                guard let self else { return }
                Task { await self.handleLocalRespawnConfirmed(playerID: playerID, reason: reason, position: position) }
            }
        }
    }

    private func handleLocalRespawnConfirmed(playerID: UUID, reason: RespawnReason, position: RespawnPosition) async {
        guard playerID == self.localPlayerID else { return }
        guard let peerName = self.peerName else { return }

        let dto = NetworkGameInputDTO.respawnRequested(
            reason: self.encodeRespawnReason(reason),
            x: position.x,
            y: position.y
        )
        self.sendDTO(dto, to: peerName)
    }
    
    private func encodeRespawnReason(_ reason: RespawnReason) -> Int {
        switch reason {
        case .fell:
            return 0
        case .hitMonster:
            return 1
        }
    }
    
    private func decodeRespawnReason(_ raw: Int) -> RespawnReason? {
        switch raw {
        case 0:
            return .fell
        case 1:
            return .hitMonster
        default:
            return nil
        }
    }

    // MARK: - Send (input -> cache)

    private func startForwardingLocalInput() async {
        remoteSendTask?.cancel()

        remoteSendTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let stream = await self.inputProvider.events()
            for await event in stream {
                if Task.isCancelled { break }

                switch event {
                case .horizontal(let x):
                    await self.setPendingLocalMoveX(x)
                case .jump:
                    // 점프는 tryJump 검증 통과 시 onJumpTriggered에서만 전송
                    break
                }
            }
        }
    }

    private func setPendingLocalMoveX(_ x: Double) {
        self.pendingLocalMoveX = x
    }

    private func installLocalJumpTriggeredSender() async {
        await MainActor.run {
            self.gameplayManager.onJumpTriggered = { [weak self] playerID in
                guard let self else { return }
                Task { await self.handleLocalJumpTriggered(playerID: playerID) }
            }
        }
    }

    private func handleLocalJumpTriggered(playerID: UUID) async {
        guard playerID == self.localPlayerID else { return }
        guard let peerName = self.peerName else { return }
        self.sendDTO(.jumpTriggered, to: peerName)
    }

    // MARK: - Tick send + smoothing

    private func sendMovementSnapshotIfNeeded(deltaTime: TimeInterval) async {
        guard let peerName = peerName else { return }

        timeSinceLastMovementSend += deltaTime
        movementSendAccumulator += deltaTime
        guard movementSendAccumulator >= movementSendInterval else { return }
        movementSendAccumulator -= movementSendInterval

        // 스냅샷 소스는 "현재 캐릭터 상태" 기반이 더 일관적(입력 지터 방지)
        let fallback = pendingLocalMoveX
        let currentMoveX = await MainActor.run {
            gameplayManager.state.characters[localPlayerID]?.moveX ?? fallback
        }

        // 간단 quantize(페이로드 안정화)
        let quantized = (currentMoveX * 100).rounded() / 100
        
        let hasSignificantChange = abs(quantized - lastSentMoveX) >= movementSendThreshold
        let isKeepAliveDue = timeSinceLastMovementSend >= movementKeepAliveInterval
        guard hasSignificantChange || isKeepAliveDue else { return }
        
        // 전송 성공 기준으로 reset
        timeSinceLastMovementSend = 0
        lastSentMoveX = quantized
        sendDTO(.horizontal(quantized), to: peerName)
    }

    private func updateRemoteInterpolation(deltaTime: TimeInterval) async {
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
        let moveX = remoteSmoothedMoveX
        await MainActor.run {
            gameplayManager.updateMoveX(moveX, for: remotePlayerID)
        }
    }

    private func sendDTO(_ dto: NetworkGameInputDTO, to peerName: String) {
        networkSessionManager.sendInput(dto, to: peerName)
    }
}
