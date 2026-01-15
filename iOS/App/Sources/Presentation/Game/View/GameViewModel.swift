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
    // TODO: 닉네임이나 id 둘중 하나로 관리되게 통일하기
    public let myNickname: String
    public let matchNickname: String?
    public let localPlayerID: UUID
    public let otherPlayerIDs: [UUID]
    
    let gameplayManager: GameplayManager
    
    @ObservationIgnored
    let inputProvider: FaceTrackingGameInputProvider
    
    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging?
    
    // TODO: 멀티플레이 입력 송수신 연결 시점에 실제 어댑터로 교체
    let webSocketSessionManager: WebSocketSessionManaging?
    
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
        myNickname: String,
        matchNickname: String?, // 추후 배열로 받아 다수를 추가할 수 있음
        endCondition: any GameEndCondition,
        networkSessionManager: NetworkSessionManaging? = nil,
        webSocketSessionManager: WebSocketSessionManaging? = nil,
        inputProvider: FaceTrackingGameInputProvider = FaceTrackingGameInputProvider()
    ) {
        self.myNickname = myNickname
        self.matchNickname = matchNickname
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.inputProvider = inputProvider
        
        self.localPlayerID = UUID()
        
        if matchNickname != nil {
            self.otherPlayerIDs = [UUID()]
        } else {
            self.otherPlayerIDs = []
        }
        
        self.gameplayManager = GameplayManager(
            localPlayerID: localPlayerID,
            otherPlayerIDs: otherPlayerIDs,
            endCondition: endCondition
        )
    }
    
    public func start() {
        gameplayManager.startNewGame()
        gameplayManager.bind(input: inputProvider, for: localPlayerID)
        // TODO: 로컬 입력 → 네트워크 전송, 네트워크 수신 → 상대 플레이어 입력 주입
    }

    public func stop() {
        gameplayManager.unbind()
    }
}
