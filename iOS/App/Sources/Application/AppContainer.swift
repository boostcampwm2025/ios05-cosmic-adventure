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
    func makeLobbyViewModel(playerId: UUID, nickname: String, characterType: String) -> LobbyViewModel
    func makeGameReadyViewModel(me: PlayerInfo, peer: PlayerInfo, isNetwork: Bool) -> GameReadyViewModel
    func makeChannelListViewModel() -> ChannelListViewModel
    func makeSettingsViewModel(player: Player) -> SettingsViewModel
    func makeWebSocketSessionManager(serverURL: String) -> WebSocketSessionManager
    func makeGameViewModel(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, gameConfig: GameConfigProviding, isNetwork: Bool) -> GameViewModel
    func makeVideoManager() -> VideoManager
    var explorationCoordinator: NetworkExplorationCoordinator { get }
}

final class AppContainer: ViewModelFactory {
    private let permissionService: PermissionServicing
    private let connectivityMonitor: ConnectivityMonitoring
    private let networkSessionManager: NetworkSessionManaging
    private let webSocketService: WebSocketService
    private let webSocketSessionManager: WebSocketSessionManaging?
    private let channelService: ChannelServiceProtocol
    let explorationCoordinator: NetworkExplorationCoordinator

    private lazy var videoManager: VideoManager = {
        VideoManager(
            connectivityMonitor: connectivityMonitor,
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
        self.permissionService = permissionService
            ?? DefaultPermissionService(
                localNetworkRequester: LocalNetworkPermissionRequester(
                    networkSessionManager: networkSessionManager
                ),
                notificationRequester: NotificationPermissionRequester()
            )
        self.explorationCoordinator = NetworkExplorationCoordinator(
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager
        )

        _ = NotificationManager.shared
    }
    
    func makePermissionSetupViewModel() -> PermissionSetupViewModel {
        PermissionSetupViewModel(service: permissionService)
    }
    
    func makeProfileSetupViewModel() -> ProfileSetupViewModel {
        ProfileSetupViewModel()
    }
    
    func makeLobbyViewModel(playerId: UUID, nickname: String, characterType: String) -> LobbyViewModel {
        LobbyViewModel(
            explorationCoordinator: explorationCoordinator,
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager,
            playerId: playerId,
            nickname: nickname,
            characterRawValue: characterType
        )
    }

    func makeGameReadyViewModel(me: PlayerInfo, peer: PlayerInfo, isNetwork: Bool) -> GameReadyViewModel {
        GameReadyViewModel(
            me: me,
            peer: peer,
            isNetwork: isNetwork,
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager
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

    func makeVideoManager() -> VideoManager {
        return videoManager
    }

    // TODO: 게임 결과 화면 뷰모델 생성
}
