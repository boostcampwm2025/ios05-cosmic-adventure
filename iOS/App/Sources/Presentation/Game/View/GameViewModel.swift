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

    public let localPlayerID: UUID
    public let remotePlayerIDs: [UUID]
    
    let gameplayManager: GameplayManager
    let gameConfig: GameConfigProviding
    
    @ObservationIgnored
    let inputProvider: FaceTrackingGameInputProvider
    
    @ObservationIgnored
    var connectionSessionManager: ConnectionSessionManaging
    
    // Multiplayer Network IO
    @ObservationIgnored
    private var multiplayerIO: MultiplayerNetworkIO?
    
    // ViewState
    var endReason: GameEndReason? {
        gameplayManager.gameEnd.endReason
    }
    
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
        gameConfig: GameConfigProviding
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
        
        self.multiplayerIO = MultiplayerNetworkIO(
            localPlayerID: localPlayerID,
            remotePlayerIDs: remotePlayerIDs,
            gameplayManager: gameplayManager,
            inputProvider: inputProvider,
            networkSessionManager: connectionSessionManager
        )
    }
    
    public func start() {
        gameplayManager.startNewGame()
        // 로컬 입력 바인드
        gameplayManager.bind(input: inputProvider, for: localPlayerID)
        
        // 네트워크 송신/수신 바인딩 (멀티플레이일 때만)
        if let remotePlayerId {
            multiplayerIO?.bind(peerId: remotePlayerId)
        } else {
            multiplayerIO?.unbind()
        }

        // GameScene이 gameplayManager.update(deltaTime:)를 호출하므로,
        // 동일 틱에 네트워크 처리/보간이 수행되도록 콜백 설정
        gameplayManager.onDidUpdate = { [weak self] deltaTime in
            self?.multiplayerIO?.tick(deltaTime: deltaTime)
        }
        
        inputProvider.start()
    }

    public func stop() {
        multiplayerIO?.unbind()
        gameplayManager.onDidUpdate = nil
        gameplayManager.onJumpTriggered = nil

        gameplayManager.unbind()
        inputProvider.stop()
    }
}
