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
    public let me: LobbyExplorer
    public let matchPeer: LobbyExplorer?
    
    // TODO: 닉네임이나 id 둘중 하나로 관리되게 통일하기
    var myNickname: String { me.displayName }
    var matchNickname: String? { matchPeer?.displayName }

    public let localPlayerID: UUID
    public let otherPlayerIDs: [UUID]
    
    let gameplayManager: GameplayManager
    
    @ObservationIgnored
    let inputProvider: FaceTrackingGameInputProvider
    
    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging
    
    // TODO: 멀티플레이 입력 송수신 연결 시점에 실제 어댑터로 교체
    let webSocketSessionManager: WebSocketSessionManaging?
    
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
        me: LobbyExplorer,
        matchPeer: LobbyExplorer?,
        endCondition: any GameEndCondition,
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging? = nil,
        inputProvider: FaceTrackingGameInputProvider = FaceTrackingGameInputProvider()
    ) {
        self.me = me
        self.matchPeer = matchPeer
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.inputProvider = inputProvider
        
        self.localPlayerID = UUID()
        
        if matchPeer != nil {
            self.otherPlayerIDs = [UUID()]
        } else {
            self.otherPlayerIDs = []
        }
        
        self.gameplayManager = GameplayManager(
            localPlayerID: localPlayerID,
            otherPlayerIDs: otherPlayerIDs,
            endCondition: endCondition
        )
        
        self.multiplayerIO = MultiplayerNetworkIO(
            localPlayerID: localPlayerID,
            otherPlayerIDs: otherPlayerIDs,
            gameplayManager: gameplayManager,
            inputProvider: inputProvider,
            networkSessionManager: networkSessionManager
        )
    }
    
    public func start() {
        gameplayManager.startNewGame()
        // 로컬 입력 바인드
        gameplayManager.bind(input: inputProvider, for: localPlayerID)
        
        // 네트워크 송신/수신 바인딩 (멀티플레이일 때만)
        if let matchNickname {
            multiplayerIO?.bind(peerName: matchNickname)
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
