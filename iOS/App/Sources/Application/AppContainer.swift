//
//  AppContainer.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

import Foundation
import NetworkKit
import Games
import StorageKit

@MainActor
protocol ViewModelFactory {
    func makePermissionSetupViewModel() -> PermissionSetupViewModel
    func makeProfileSetupViewModel() -> ProfileSetupViewModel
    func makeLobbyViewModel(player: Player) -> LobbyViewModel
    func makeGameReadyViewModel(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool) -> GameReadyViewModel
    func makeChannelListViewModel() -> ChannelListViewModel
    func makeSettingsViewModel(player: Player) -> SettingsViewModel
    func makeWebSocketSessionManager(serverURL: String) -> WebSocketSessionManager
    func makeGameViewModel(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, gameConfig: GameConfigProviding, isNetwork: Bool) -> GameViewModel
    func makeVideoManager(isNetwork: Bool) -> VideoManager
    var explorationCoordinator: NetworkExplorationCoordinator { get }
    var appEntryManager: AppEntryManager { get }
}

final class AppContainer: ViewModelFactory {
    private let permissionService: PermissionServicing
    private let connectivityMonitor: ConnectivityMonitoring
    private let networkSessionManager: NetworkSessionManaging
    private let webSocketService: WebSocketService
    private let webSocketSessionManager: WebSocketSessionManaging?
    private let channelService: ChannelServiceProtocol
    let explorationCoordinator: NetworkExplorationCoordinator
    let appEntryManager: AppEntryManager

    private lazy var videoManager: VideoManager = {
        VideoManager(
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager
        )
    }()
    
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
        
        // 권한 확인용 별도 인스턴스 사용: LocalNetworkPermissionRequester가 권한 확인 후
        // deactivate()를 호출하므로, 공유 networkSessionManager를 사용하면 진행 중인 P2P 세션이 중단됨
        let permissionCheckSessionManager = NetworkSessionManager()
        let resolvedPermissionService = permissionService
            ?? DefaultPermissionService(
                localNetworkRequester: LocalNetworkPermissionRequester(
                    networkSessionManager: permissionCheckSessionManager
                ),
                notificationRequester: NotificationPermissionRequester()
            )
        self.permissionService = resolvedPermissionService
        
        self.appEntryManager = AppEntryManager(permissionService: resolvedPermissionService)
        
        self.explorationCoordinator = NetworkExplorationCoordinator(
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager
        )

        _ = NotificationManager.shared
    }
    
    func makePermissionSetupViewModel() -> PermissionSetupViewModel {
        PermissionSetupViewModel(service: permissionService, appEntryManager: appEntryManager)
    }
    
    func makeProfileSetupViewModel() -> ProfileSetupViewModel {
        ProfileSetupViewModel()
    }
    
    func makeLobbyViewModel(player: Player) -> LobbyViewModel {
        LobbyViewModel(
            explorationCoordinator: explorationCoordinator,
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager,
            appEntryManager: appEntryManager,
            player: player
        )
    }

    func makeGameReadyViewModel(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool) -> GameReadyViewModel {
        GameReadyViewModel(
            localPlayer: localPlayer,
            remotePlayer: remotePlayer,
            isNetwork: isNetwork,
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager,
            appEntryManager: appEntryManager
        )
    }

    func makeChannelListViewModel() -> ChannelListViewModel {
        ChannelListViewModel(channelService: channelService)
    }
    
    func makeSettingsViewModel(player: Player) -> SettingsViewModel {
        SettingsViewModel(player: player)
    }

    func makeWebSocketSessionManager(serverURL: String) -> WebSocketSessionManager {
        WebSocketSessionManager(service: webSocketService, serverURL: serverURL)
    }

    func makeGameViewModel(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, gameConfig: GameConfigProviding, isNetwork: Bool = false) -> GameViewModel {
        GameViewModel(
            localPlayer: localPlayer,
            remotePlayer: remotePlayer,
            endCondition: TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 10),
            connectionSessionManager: isNetwork ? webSocketSessionManager ?? networkSessionManager : networkSessionManager,
            gameConfig: gameConfig
        )
    }

    func makeVideoManager(isNetwork: Bool) -> VideoManager {
        videoManager.reset()
        videoManager.setNetworkMode(isNetwork: isNetwork)

        return videoManager
    }

    // TODO: 게임 결과 화면 뷰모델 생성
}
