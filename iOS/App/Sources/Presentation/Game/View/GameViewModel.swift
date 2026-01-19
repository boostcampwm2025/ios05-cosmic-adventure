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
    private var remoteInputProvider: NetworkGameInputProvider?
    
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
    }

    public func stop() {
        clearMultiplayerNetworkBindings()
        remoteInputProvider?.stop()
        remoteInputProvider = nil

        gameplayManager.unbind()
        inputProvider.stop()
    }
}

// MARK: remote 연결

extension GameViewModel {
    private func bindMultiplayerNetworkIO() {
        guard let matchNickname else {
            clearMultiplayerNetworkBindings()
            return
        }

        // 원격(상대) 입력 바인딩 (네트워크 수신 이벤트를 GameInputProviding으로 변환)
        bindRemotePlayerInputIfNeeded()
        
        // 네트워크 수신/송신 연결
        setRemoteInputReceiveHandler(for: matchNickname)
        startForwardingLocalInput(to: matchNickname)
    }

    // MARK: - Remote Player Input Binding

    /// 멀티플레이일 때 상대 플레이어 입력 스트림을 GameplayManager에 바인딩
    private func bindRemotePlayerInputIfNeeded() {
        // 이미 바인딩 되어 있다면 재생성/재바인딩하지 않음
        guard remoteInputProvider == nil else { return }
        guard let remotePlayerID = otherPlayerIDs.first else { return }

        let provider = NetworkGameInputProvider()
        remoteInputProvider = provider
        gameplayManager.bind(input: provider, for: remotePlayerID)
        provider.start()
    }

    // MARK: - Receive

    private func setRemoteInputReceiveHandler(for peerName: String) {
        networkSessionManager.onInputReceived = { sender, payload in
            guard sender == peerName else { return }

            guard let dto = try? JSONDecoder().decode(NetworkGameInputDTO.self, from: payload) else {
                print("[NET][RECV] decode failed from \(sender)")
                return
            }
            
            switch dto.kind {
            case .horizontal:
                self.remoteInputProvider?.yield(.horizontal(Double(dto.x ?? 0)))
            case .jump:
                self.remoteInputProvider?.yield(.jump)
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
        networkSessionManager.onInputReceived = nil
    }
}
