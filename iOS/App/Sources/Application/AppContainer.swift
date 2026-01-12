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
    func makeLobbyViewModel() -> LobbyViewModel
    func makeChannelListViewModel() -> ChannelListViewModel
}

final class AppContainer: ViewModelFactory {
    private let permissionService: PermissionServicing
    private let connectivityMonitor: ConnectivityMonitoring
    private let networkSessionManager: ConnectionSessionProvider
    private let webSocketService: WebSocketService
    private let webSocketSessionManager: WebSocketSessionManaging?
    private let channelService: ChannelServiceProtocol
    
    init(
        permissionService: PermissionServicing? = nil,
        connectivityMonitor: ConnectivityMonitoring = ConnectivityMonitor(),
        networkSessionManager: ConnectionSessionProvider = NetworkSessionManager(),
        webSocketService: WebSocketService = WebSocketService(),
        webSocketSessionManager: WebSocketSessionManaging? = nil
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketService = webSocketService
        self.webSocketSessionManager = webSocketSessionManager
        self.channelService = ChannelService(
            httpClient: HTTPClient(),
            baseURL: "http://localhost:8080"
        )
        self.permissionService = permissionService
            ?? DefaultPermissionService(
                localNetworkRequester: LocalNetworkPermissionRequester(
                    sessionProvider: networkSessionManager
                )
            )
    }
    
    func makePermissionSetupViewModel() -> PermissionSetupViewModel {
        PermissionSetupViewModel(service: permissionService)
    }
    
    func makeProfileSetupViewModel() -> ProfileSetupViewModel {
        ProfileSetupViewModel()
    }
    
    func makeLobbyViewModel() -> LobbyViewModel {
        LobbyViewModel(
            connectivityMonitor: connectivityMonitor,
            sessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager,
            nickname: "건방진 탐험가 123"
        )
    }
    
    func makeChannelListViewModel() -> ChannelListViewModel {
        ChannelListViewModel(channelService: channelService)
    }

    func makeWebSocketSessionManager(serverURL: String, channelId: String) -> WebSocketSessionManager {
        WebSocketSessionManager(service: webSocketService, serverURL: serverURL, channelId: channelId)
    }

    // TODO: 게임 화면 서비스 객체 연결

    // TODO: 게임 결과 화면 뷰모델 생성

}
