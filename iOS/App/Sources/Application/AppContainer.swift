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
}

final class AppContainer: ViewModelFactory {
    private let permissionService: PermissionServicing
    private let connectivityMonitor: ConnectivityMonitoring
    private let networkSessionManager: NetworkSessionManager
    private let webSocketService: WebSocketService
    private let webSocketSessionManager: WebSocketSessionManaging?
    // TODO: 유저 프로필 관리 객체 소유
    
    init(
        permissionService: PermissionServicing? = nil,
        connectivityMonitor: ConnectivityMonitoring = ConnectivityMonitor(),
        networkSessionManager: NetworkSessionManager = NetworkSessionManager(),
        webSocketService: WebSocketService = WebSocketService(),
        webSocketSessionManager: WebSocketSessionManaging? = nil
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketService = webSocketService
        self.webSocketSessionManager = webSocketSessionManager
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

    func makeWebSocketSessionManager(serverURL: String, channelId: String) -> WebSocketSessionManager {
        WebSocketSessionManager(service: webSocketService, serverURL: serverURL, channelId: channelId)
    }

    // TODO: 게임 화면 서비스 객체 연결

    // TODO: 게임 결과 화면 뷰모델 생성

}
