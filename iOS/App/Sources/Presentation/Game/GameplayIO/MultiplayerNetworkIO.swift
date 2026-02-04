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

protocol MultiplayerNetworkManaging: AnyObject {
    func bind(peerId: UUID)
    func unbind()
    func notifyGameEnded(_ reason: GameEndReason)
    func setOnGameEndReceived(_ handler: @escaping @Sendable (NetworkGameEndDTO) -> Void)
    func setOnPeerDisconnected(_ handler: @escaping @Sendable () -> Void)
    func tick(deltaTime: TimeInterval)
}

actor MultiplayerNetworkIO: MultiplayerNetworkManaging {
    private let localPlayer: PlayerInfo
    private let remotePlayers: [PlayerInfo]
    private let gameplayManager: GameplayManager
    private let inputProvider: FaceTrackingGameInputProvider
    private var connectionSessionManager: ConnectionSessionManaging

    private let jsonDecoder = JSONDecoder()

    private var peerId: UUID?

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

    private var didSendGameEnd: Bool = false

    private var onGameEndReceived: (@Sendable (NetworkGameEndDTO) -> Void)?
    private var onPeerDisconnected: (@Sendable () -> Void)?

    private var localPlayerID: UUID { localPlayer.id }
    private var remotePlayerIDs: [UUID] { remotePlayers.map(\.id) }
    private var localDisplayName: String { localPlayer.displayName }
    private var remoteDisplayName: String? { remotePlayers.first?.displayName }
    
    /// 지터를 줄이기 위한 smoothing 상수(작을수록 반응이 빠름)
    private let remoteSmoothingTimeConstant: TimeInterval = 0.08

    /// 이 시간 이상 원격 수신이 없으면 moveX=0 강제 적용
    private let remoteFreezeAfter: TimeInterval = 0.8

    /// 이 시간 이상 원격 수신이 없으면 연결 끊김으로 판단
    private let peerTimeoutInterval: TimeInterval = 3.0
    private var didNotifyPeerTimeout: Bool = false

    init(
        localPlayer: PlayerInfo,
        remotePlayers: [PlayerInfo],
        gameplayManager: GameplayManager,
        inputProvider: FaceTrackingGameInputProvider,
        networkSessionManager: ConnectionSessionManaging
    ) {
        self.localPlayer = localPlayer
        self.remotePlayers = remotePlayers
        self.gameplayManager = gameplayManager
        self.inputProvider = inputProvider
        self.connectionSessionManager = networkSessionManager
    }

    // MARK: - Public entrypoints (non-async friendly)

    nonisolated func bind(peerId: UUID) {
        Task { await self.bindAsync(peerId: peerId) }
    }

    nonisolated func unbind() {
        Task { await self.unbindAsync() }
    }

    nonisolated func notifyGameEnded(_ reason: GameEndReason) {
        Task { await self.notifyGameEndedAsync(reason) }
    }

    nonisolated func setOnGameEndReceived(_ handler: @escaping @Sendable (NetworkGameEndDTO) -> Void) {
        Task { await self.setOnGameEndReceivedAsync(handler) }
    }

    nonisolated func setOnPeerDisconnected(_ handler: @escaping @Sendable () -> Void) {
        Task { await self.setOnPeerDisconnectedAsync(handler) }
    }

    /// gameplayManager.update(deltaTime:)와 동일 틱에 실행되는 네트워크 처리
    /// `SKScene.update`는 동기(sync)로 호출되기 때문에, 여기서 바로 `await`를 사용할 수 없어
    ///  실제 작업을 `Task`로 감싸 actor 큐에 등록(enqueue)하여 비동기로 처리합니다.
    nonisolated func tick(deltaTime: TimeInterval) {
        Task { await self.tickAsync(deltaTime: deltaTime) }
    }

    // MARK: - Actor-isolated implementations

    private func bindAsync(peerId: UUID) async {
        self.peerId = peerId

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
        didSendGameEnd = false
        didNotifyPeerTimeout = false
    }

    private func setOnGameEndReceivedAsync(_ handler: @escaping @Sendable (NetworkGameEndDTO) -> Void) async {
        onGameEndReceived = handler
    }

    private func setOnPeerDisconnectedAsync(_ handler: @escaping @Sendable () -> Void) async {
        onPeerDisconnected = handler
    }

    private func unbindAsync() async {
        peerId = nil

        remoteSendTask?.cancel()
        remoteSendTask = nil

        await MainActor.run {
            self.gameplayManager.onJumpTriggered = nil
            self.gameplayManager.onRespawnConfirmed = nil
        }
        connectionSessionManager.onInputReceived = nil
        connectionSessionManager.onGameEnded = nil
        onPeerDisconnected = nil
    }

    private func notifyGameEndedAsync(_ reason: GameEndReason) async {
        guard didSendGameEnd == false else { return }
        guard let peerId else { return }
        didSendGameEnd = true

        if reason == .reachedFinish {
            await MainActor.run {
                gameplayManager.gameEnd.updateWinner(localPlayer.id)
            }
        }

        let dto = await makeGameEndDTO(reason: reason)

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await connectionSessionManager.sendGameEnded(dto, to: peerId)
        }

        onGameEndReceived?(dto)
    }

    private func tickAsync(deltaTime: TimeInterval) async {
        guard peerId != nil else { return }
        await sendMovementSnapshotIfNeeded(deltaTime: deltaTime)
        await updateRemoteInterpolation(deltaTime: deltaTime)
        await sendGameEndIfNeeded()
    }

    // MARK: - Receive

    private func installReceiveHandler() async {
        connectionSessionManager.onInputReceived = { [weak self] sender, payload in
            guard let self else { return }
            Task { await self.handleReceivedInput(sender: sender, payload: payload) }
        }
        connectionSessionManager.onGameEnded = { [weak self] sender, dto in
            guard let self else { return }
            Task { await self.handleReceivedGameEnd(sender: sender, dto: dto) }
        }
    }

    private func handleReceivedInput(sender: UUID, payload: Data) async {
        guard let peerId = self.peerId, sender == peerId else { return }
        guard let remotePlayerID = self.remotePlayerIDs.first else { return }

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

    private func handleReceivedGameEnd(sender: UUID, dto: NetworkGameEndDTO) async {
        guard let peerId = self.peerId, sender == peerId else { return }
        guard let reason = decodeGameEndReason(dto.reason) else { return }
        didSendGameEnd = true

        await MainActor.run {
            var finalWinner: UUID? = nil

            if let winnerIdFromDTO = dto.winnerId {
                finalWinner = winnerIdFromDTO
            } else if reason == .timeout {
                let myIndex = gameplayManager.gameEnd.lastLandedPlatformIndex
                let opponentIndex = dto.lastSafePlatformIndex

                if myIndex > opponentIndex {
                    finalWinner = localPlayer.id
                } else if opponentIndex > myIndex {
                    finalWinner = sender
                }
            }

            gameplayManager.gameEnd.updateWinner(finalWinner)
        }

        onGameEndReceived?(dto)
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
        guard let peerId = self.peerId else { return }

        let dto = NetworkGameInputDTO.respawnRequested(
            reason: self.encodeRespawnReason(reason),
            x: position.x,
            y: position.y
        )
        self.sendDTO(dto, to: peerId)
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

    private func encodeGameEndReason(_ reason: GameEndReason) -> GameEndReasonCode {
        switch reason {
        case .timeout:
            return .timeout
        case .reachedFinish:
            return .reachedFinish
        case .quit:
            return .quit
        }
    }

    private func decodeGameEndReason(_ code: GameEndReasonCode) -> GameEndReason? {
        switch code {
        case .timeout:
            return .timeout
        case .reachedFinish:
            return .reachedFinish
        case .quit:
            return .quit
        }
    }

    private func sendGameEndIfNeeded() async {
        guard didSendGameEnd == false else { return }
        guard let peerId = self.peerId else { return }

        let endReason: GameEndReason? = await MainActor.run {
            self.gameplayManager.gameEnd.endReason
        }
        guard let endReason else { return }

        didSendGameEnd = true
        let dto = await makeGameEndDTO(reason: endReason)
        connectionSessionManager.sendGameEnded(dto, to: peerId)
    }

    // 종료 신호를 보낼 때
    private func makeGameEndDTO(reason: GameEndReason) async -> NetworkGameEndDTO {
        let (myIndex, myElapsed, winnerId) = await MainActor.run {
            let gameEnd = gameplayManager.gameEnd
            return (
                gameEnd.lastLandedPlatformIndex,
                gameEnd.elapsedSeconds,
                gameEnd.winnerID
            )
        }

        return NetworkGameEndDTO(
            reason: encodeGameEndReason(reason),
            winnerId: winnerId,
            winnerElapsedSeconds: myElapsed,
            winnerName: localPlayer.displayName,
            lastSafePlatformIndex: myIndex
        )
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
        guard let peerId = self.peerId else { return }
        self.sendDTO(.jumpTriggered, to: peerId)
    }

    // MARK: - Tick send + smoothing

    private func sendMovementSnapshotIfNeeded(deltaTime: TimeInterval) async {
        guard let peerId = peerId else { return }

        timeSinceLastMovementSend += deltaTime
        movementSendAccumulator += deltaTime
        guard movementSendAccumulator >= movementSendInterval else { return }
        movementSendAccumulator -= movementSendInterval

        // 스냅샷 소스는 "현재 캐릭터 상태" 기반이 더 일관적(입력 지터 방지)
        let fallback = pendingLocalMoveX
        let localID = localPlayerID
        let currentMoveX = await MainActor.run {
            gameplayManager.state.characters[localID]?.moveX ?? fallback
        }

        // 간단 quantize(페이로드 안정화)
        let quantized = (currentMoveX * 100).rounded() / 100
        
        let hasSignificantChange = abs(quantized - lastSentMoveX) >= movementSendThreshold
        let isKeepAliveDue = timeSinceLastMovementSend >= movementKeepAliveInterval
        guard hasSignificantChange || isKeepAliveDue else { return }
        
        // 전송 성공 기준으로 reset
        timeSinceLastMovementSend = 0
        lastSentMoveX = quantized
        sendDTO(.horizontal(quantized), to: peerId)
    }

    private func updateRemoteInterpolation(deltaTime: TimeInterval) async {
        guard let remotePlayerID = remotePlayerIDs.first else { return }

        // liveness: 일정 시간 수신이 없으면 안전하게 멈추기
        let now = Date().timeIntervalSince1970
        if (now - lastRemoteReceivedAt) > remoteFreezeAfter, didForceStopRemote == false {
            didForceStopRemote = true
            remoteTargetMoveX = 0
        }

        // 장시간 수신 없으면 연결 끊김으로 판단
        if (now - lastRemoteReceivedAt) > peerTimeoutInterval, !didNotifyPeerTimeout {
            didNotifyPeerTimeout = true
            onPeerDisconnected?()
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

    private func sendDTO(_ dto: NetworkGameInputDTO, to peerId: UUID) {
        connectionSessionManager.sendGameData(dto, to: peerId)
    }
}
