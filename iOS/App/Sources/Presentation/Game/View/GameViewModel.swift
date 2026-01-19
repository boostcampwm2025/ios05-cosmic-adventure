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
    var networkSessionManager: NetworkSessionManaging
    
    // TODO: 멀티플레이 입력 송수신 연결 시점에 실제 어댑터로 교체
    let webSocketSessionManager: WebSocketSessionManaging?
    
    @ObservationIgnored
    private var remoteSendTask: Task<Void, Never>?
    
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
        networkSessionManager: NetworkSessionManaging,
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
        // 로컬 입력 바인드
        gameplayManager.bind(input: inputProvider, for: localPlayerID)
        // 네트워크 송신/수신 바인딩
        bindMultiplayerNetworkIO()

        inputProvider.start()
        // TODO: 네트워크 수신 → 상대 플레이어 입력 주입
    }

    public func stop() {
        remoteSendTask?.cancel()
        remoteSendTask = nil

        gameplayManager.unbind()
        inputProvider.stop()
    }
}

// MARK: remote 연결

extension GameViewModel {
    /// 멀티플레이일 때 네트워크 I/O(송신/수신) 바인딩
    /// inputProvider.events()가 hot stream(브로드캐스트)이라 구독 경쟁 없이
    /// 게임플레이 바인딩 + 네트워크 송신을 동시에 수행할 수 있습니다.
    private func bindMultiplayerNetworkIO() {
        guard let matchNickname else {
            clearMultiplayerNetworkBindings()
            return
        }

        setRemoteInputReceiveHandler(for: matchNickname)
        startForwardingLocalInput(to: matchNickname)
    }

    // MARK: - Receive

    private func setRemoteInputReceiveHandler(for peerName: String) {
        // TODO: 수신 부 연결하기
        networkSessionManager.onInputReceived = { sender, payload in
            guard sender == peerName else { return }

            guard let dto = try? JSONDecoder().decode(NetworkGameInputDTO.self, from: payload) else {
                print("[NET][RECV] decode failed from \(sender)")
                return
            }

            switch dto.kind {
            case .horizontal:
                print("[NET][RECV] horizontal: \(dto.x ?? 0) from \(sender)")
            case .jump:
                print("[NET][RECV] jump from \(sender)")
            }
        }
    }

    // MARK: - Send

    private func startForwardingLocalInput(to peerName: String) {
        remoteSendTask?.cancel()
        remoteSendTask = Task { [weak self] in
            guard let self else { return }

            let stream = await self.inputProvider.events()
            for await event in stream {
                if Task.isCancelled { break }

                switch event {
                case .horizontal(let x):
                    self.networkSessionManager.sendInput(NetworkGameInputDTO.horizontal(x), to: peerName)
                case .jump:
                    self.networkSessionManager.sendInput(NetworkGameInputDTO.jump, to: peerName)
                }
            }
        }
    }

    // MARK: - Cleanup

    private func clearMultiplayerNetworkBindings() {
        remoteSendTask?.cancel()
        remoteSendTask = nil
        // TODO: 수신부 초기화
        networkSessionManager.onInputReceived = nil
    }
}
