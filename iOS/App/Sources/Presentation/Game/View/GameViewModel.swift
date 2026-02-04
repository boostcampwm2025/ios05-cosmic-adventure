//
//  GameViewModel.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/15/26.
//

import Games
import InputSystem
import SpriteKit
import NetworkKit

@MainActor
@Observable
final class GameViewModel {
    public let localPlayer: PlayerInfo
    public let remotePlayer: PlayerInfo?
    
    var remotePlayerId: UUID? { remotePlayer?.id }
    
    /// 상대 플레이어의 화면 좌표
    var remotePlayerScreenPosition: CGPoint = .zero
    var isRemotePlayerVisible: Bool = false

    public let localPlayerID: UUID
    public let remotePlayerIDs: [UUID]
    
    let gameplayManager: GameplayManager
    let gameConfig: GameConfigProviding

    var shouldNavigateToResult: Bool = false

    @ObservationIgnored
    let inputProvider: FaceTrackingGameInputProvider
    
    @ObservationIgnored
    var connectionSessionManager: ConnectionSessionManaging
    
    // Multiplayer Network IO
    @ObservationIgnored
    private var multiplayerIO: MultiplayerNetworkManaging?
    
    // ViewState
    var endReason: GameEndReason? {
        gameplayManager.gameEnd.endReason
    }

    struct GameEndDisplay: Equatable, Hashable {
        let reason: GameEndReason
        let winnerId: UUID?
        let localElapsedSeconds: Int?
        let winnerElapsedSeconds: Int?
        let winnerName: String?
        let opponentName: String?
    }

    var gameEndDisplay: GameEndDisplay?
    var showDisconnectAlert: Bool = false
    
    var remainingSeconds: Int? {
        gameplayManager.gameEnd.remainingSeconds
    }
    
    var elapsedSeconds: Int {
        gameplayManager.gameEnd.elapsedSeconds
    }
    
    init(
        localPlayer: PlayerInfo,
        remotePlayer: PlayerInfo?,
        endCondition: any GameEndCondition,
        connectionSessionManager: ConnectionSessionManaging,
        gameConfig: GameConfigProviding,
        multiplayerIO: MultiplayerNetworkManaging? = nil
    ) {
        self.localPlayer = localPlayer
        self.remotePlayer = remotePlayer
        self.connectionSessionManager = connectionSessionManager
        self.gameConfig = gameConfig
        self.inputProvider = FaceTrackingGameInputProvider(
            jumpSensitivity: gameConfig.jumpSensitivity,
            tiltSensitivity: gameConfig.tiltSensitivity
        )
        
        self.localPlayerID = localPlayer.id
        
        if let remotePlayer {
            self.remotePlayerIDs = [remotePlayer.id]
        } else {
            self.remotePlayerIDs = []
        }
        
        self.gameplayManager = GameplayManager(
            localPlayerID: localPlayerID,
            remotePlayerIDs: remotePlayerIDs,
            endCondition: endCondition
        )
        
        if let multiplayerIO {
            self.multiplayerIO = multiplayerIO
        } else {
            self.multiplayerIO = MultiplayerNetworkIO(
                localPlayer: localPlayer,
                remotePlayers: remotePlayer.map { [$0] } ?? [],
                gameplayManager: gameplayManager,
                inputProvider: inputProvider,
                networkSessionManager: connectionSessionManager
            )
        }

        if remotePlayerId != nil {
            self.multiplayerIO?.setOnGameEndReceived { [weak self] dto in
                Task { @MainActor in
                    self?.applyRemoteGameEnd(dto)
                }
            }
        }
    }
    
    func start() {
        gameplayManager.startNewGame()
        // 로컬 입력 바인드
        gameplayManager.bind(input: inputProvider, for: localPlayerID)
        
        // 네트워크 송신/수신 바인딩 (멀티플레이일 때만)
        if let remotePlayerId {
            multiplayerIO?.bind(peerId: remotePlayerId)
            multiplayerIO?.setOnPeerDisconnected { [weak self] in
                Task { @MainActor in
                    self?.showDisconnectAlert = true
                }
            }
        } else {
            multiplayerIO?.unbind()
        }

        // GameScene이 gameplayManager.update(deltaTime:)를 호출하므로,
        // 동일 틱에 네트워크 처리/보간이 수행되도록 콜백 설정
        gameplayManager.onDidUpdate = { [weak self] deltaTime in
            self?.multiplayerIO?.tick(deltaTime: deltaTime)
        }
        
        connectionSessionManager.onDisconnected = { [weak self] in
            Task { @MainActor in
                self?.showDisconnectAlert = true
            }
        }

        inputProvider.start()
    }

    func stop() {
        multiplayerIO?.unbind()
        gameplayManager.onDidUpdate = nil
        gameplayManager.onJumpTriggered = nil
        connectionSessionManager.onDisconnected = nil

        gameplayManager.unbind()
        inputProvider.stop()
    }

    func bindRemotePlayerPosition(scene: GameScene) {
        scene.onRemotePlayerPositionUpdate = { [weak self] position, isVisible in
            Task { @MainActor in
                self?.remotePlayerScreenPosition = position
                self?.isRemotePlayerVisible = isVisible
            }
        }
    }

    func notifyGameEnded(_ reason: GameEndReason) {
        guard remotePlayerId != nil else { return }
        multiplayerIO?.notifyGameEnded(reason)
    }

    func requestQuitGame() {
        gameplayManager.applyGameEnd(.quit)

        notifyGameEnded(.quit)
        stop()
    }

    func requestRespawn() {
        guard endReason == nil else { return }
        gameplayManager.requestRespawn(.fell, for: localPlayerID)
    }

    func applyRemoteGameEnd(_ dto: NetworkGameEndDTO) {
        guard let reason = decodeGameEndReason(dto.reason) else { return }

        let finalWinnerId = dto.winnerId ?? gameplayManager.gameEnd.winnerID
        var winnerName: String? = nil
        var opponentName: String? = nil

        if let winnerId = finalWinnerId {
            if winnerId == localPlayerID {
                winnerName = localPlayer.displayName
                opponentName = remotePlayer?.displayName
            } else {
                winnerName = remotePlayer?.displayName
                opponentName = localPlayer.displayName
            }
        }

        self.gameEndDisplay = GameEndDisplay(
            reason: reason,
            winnerId: finalWinnerId,
            localElapsedSeconds: gameplayManager.gameEnd.elapsedSeconds,
            winnerElapsedSeconds: dto.winnerElapsedSeconds,
            winnerName: winnerName,
            opponentName: opponentName
        )

        self.shouldNavigateToResult = true
    }

    func updateLocalGameEndDisplay(_ reason: GameEndReason) {
        if reason == .reachedFinish && gameplayManager.gameEnd.winnerID == nil {
            gameplayManager.gameEnd.updateWinner(localPlayerID)
        }

        let winnerId = gameplayManager.gameEnd.winnerID

        self.gameEndDisplay = GameEndDisplay(
            reason: reason,
            winnerId: winnerId,
            localElapsedSeconds: Int(elapsedSeconds),
            winnerElapsedSeconds: reason == .reachedFinish ? Int(elapsedSeconds) : nil, // 도착 시에만 기록
            winnerName: winnerId == localPlayerID ? localPlayer.displayName : remotePlayer?.displayName,
            opponentName: winnerId == localPlayerID ? remotePlayer?.displayName : localPlayer.displayName
        )

        if remotePlayer == nil {
            self.shouldNavigateToResult = true
        } else if reason == .reachedFinish || reason == .quit {
            self.shouldNavigateToResult = true
        }
    }

    var gameEndReasonText: String? {
        guard let display = gameEndDisplay else { return nil }
        switch display.reason {
        case .timeout:
            return L10N.Game.End.timeoutTitle
        case .reachedFinish:
            if display.winnerId == localPlayerID {
                return L10N.Game.End.winTitle
            }
            if let winnerId = display.winnerId, winnerId != localPlayerID {
                return L10N.Game.End.loseTitle
            }
            return L10N.Game.End.finishTitle
        case .quit:
            return L10N.Game.End.quitTitle
        }
    }

    var gameEndWinnerText: String? {
        guard let display = gameEndDisplay else { return nil }
        if display.reason == .timeout || display.reason == .quit { return nil }
        guard let winnerName = display.winnerName else { return nil }
        return "\(L10N.Game.End.winnerPrefix): \(winnerName)"
    }

    var gameEndOpponentText: String? {
        guard let display = gameEndDisplay else { return nil }
        if display.reason == .timeout || display.reason == .quit { return nil }
        guard let opponentName = display.opponentName else { return nil }
        return "\(L10N.Game.End.opponentPrefix): \(opponentName)"
    }

    var gameEndOpponentElapsedText: String? {
        guard let display = gameEndDisplay,
              let winnerElapsed = display.winnerElapsedSeconds else { return nil }
        if display.reason == .timeout || display.reason == .quit { return nil }
        return String(format: L10N.Game.End.winnerElapsedFormat, winnerElapsed)
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
}
