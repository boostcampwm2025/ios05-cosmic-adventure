//
//  AppContainer.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

import Foundation

import NetworkKit
import Games

@MainActor
protocol ViewModelFactory {
    func makePermissionSetupViewModel() -> PermissionSetupViewModel
    func makeProfileSetupViewModel() -> ProfileSetupViewModel
    func makeLobbyViewModel(nickname: String, characterType: String) -> LobbyViewModel
    func makeGameReadyViewModel(me: LobbyExplorer, peer: LobbyExplorer) -> GameReadyViewModel
    func makeChannelListViewModel() -> ChannelListViewModel
    func makeWebSocketSessionManager(serverURL: String) -> WebSocketSessionManager
    func makeGameViewModel(myNickname: String, characterType: String, matchNickname: String?) -> GameViewModel
}

final class AppContainer: ViewModelFactory {
    private let permissionService: PermissionServicing
    private let connectivityMonitor: ConnectivityMonitoring
    private let networkSessionManager: NetworkSessionManaging
    private let webSocketService: WebSocketService
    private let webSocketSessionManager: WebSocketSessionManaging?
    private let channelService: ChannelServiceProtocol
    
    init(
        permissionService: PermissionServicing? = nil,
        connectivityMonitor: ConnectivityMonitoring = ConnectivityMonitor(),
        networkSessionManager: NetworkSessionManaging = NetworkSessionManager(),
        webSocketService: WebSocketService = WebSocketService()
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketService = webSocketService
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "http://localhost:8080"
        let wsURL = baseURL
                    .replacingOccurrences(of: "https://", with: "wss://")
                    .replacingOccurrences(of: "http://", with: "ws://")
        
        self.webSocketSessionManager = WebSocketSessionManager(
            service: webSocketService,
            serverURL: wsURL
        )
        self.channelService = ChannelService(
            httpClient: HTTPClient(),
            baseURL: baseURL
        )
        self.permissionService = permissionService
            ?? DefaultPermissionService(
                localNetworkRequester: LocalNetworkPermissionRequester(
                    networkSessionManager: networkSessionManager
                )
            )
    }
    
    func makePermissionSetupViewModel() -> PermissionSetupViewModel {
        PermissionSetupViewModel(service: permissionService)
    }
    
    func makeProfileSetupViewModel() -> ProfileSetupViewModel {
        ProfileSetupViewModel()
    }
    
    func makeLobbyViewModel(nickname: String, characterType: String) -> LobbyViewModel {
        LobbyViewModel(
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager,
            nickname: nickname,
            characterRawValue: characterType
        )
    }

    func makeGameReadyViewModel(me: LobbyExplorer, peer: LobbyExplorer) -> GameReadyViewModel {
        GameReadyViewModel(
            me: me,
            peer: peer,
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager
        )
    }

    func makeChannelListViewModel() -> ChannelListViewModel {
        ChannelListViewModel(channelService: channelService)
    }

    func makeWebSocketSessionManager(serverURL: String) -> WebSocketSessionManager {
        WebSocketSessionManager(service: webSocketService, serverURL: serverURL)
    }

    func makeGameViewModel(myNickname: String, characterType: String, matchNickname: String?) -> GameViewModel {
        
        return GameViewModel(
            myNickname: myNickname,
            matchNickname: matchNickname,
            endCondition: TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 10),
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager
        )
    }

    // TODO: 게임 결과 화면 뷰모델 생성

}
