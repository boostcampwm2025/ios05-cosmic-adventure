//
//  AppContainer.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

import Foundation

import NetworkKit

@MainActor
protocol ViewModelFactory {
    func makePermissionSetupViewModel() -> PermissionSetupViewModel
    func makeProfileSetupViewModel() -> ProfileSetupViewModel
    func makeLobbyViewModel(nickname: String, characterType: String) -> LobbyViewModel
    func makeGameReadyViewModel(me: LobbyExplorer, peer: LobbyExplorer) -> GameReadyViewModel
    func makeChannelListViewModel() -> ChannelListViewModel
    func makeWebSocketSessionManager(serverURL: String) -> WebSocketSessionManager
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
                    .replacingOccurrences(of: "http", with: "ws")
                    .replacingOccurrences(of: "https", with: "wss")
        
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

    // TODO: 게임 화면 서비스 객체 연결

    // TODO: 게임 결과 화면 뷰모델 생성

}
