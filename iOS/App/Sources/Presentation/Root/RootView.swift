//
//  RootView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

import SwiftUI
import StorageKit

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let container: AppContainer
    @State var router: AppRouter
    @Query private var players: [Player]

    init(container: AppContainer? = nil, router: AppRouter? = nil) {
        self.container = container ?? AppContainer()
        _router = State(initialValue: router ?? AppRouter())
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            screen(router.root)
                .navigationDestination(for: AppRoute.self) { route in
                    screen(route)
                }
        }
        .environment(router)
        .environment(container.appEntryManager)
        .alert(
            L10N.Common.permissionAlertTitle,
            isPresented: Binding(
                get: { container.appEntryManager.activePermissionAlert != nil },
                set: { if !$0 { container.appEntryManager.dismissAlert() } }
            )
        ) {
            Button(L10N.Common.goToSettings) { container.appEntryManager.openAppSettings() }
            Button(L10N.Common.cancel, role: .cancel) { container.appEntryManager.dismissAlert() }
        } message: {
            if let alert = container.appEntryManager.activePermissionAlert {
                switch alert {
                case .localNetworkDenied:
                    Text(L10N.Alert.localNetworkSubTitle)
                case .cameraDenied:
                    Text(L10N.Alert.cameraSubTitle)
                case .notificationDenied:
                    Text(L10N.Alert.localNetworkSubTitle)
                }
            }
        }
        .task {
            checkUserStatus()
            await handleScenePhase(.active)
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task {
                await handleScenePhase(newPhase)
            }
        }
    }

    @ViewBuilder
    func screen(_ route: AppRoute) -> some View {
        switch route {
        case .permissionSetup:
            PermissionSetupView(viewModel: container.makePermissionSetupViewModel())
        case .profileSetup:
            ProfileSetupView(viewModel: container.makeProfileSetupViewModel())
        case .lobby:
            if let localPlayer = players.first {
                LobbyView(viewModel: container.makeLobbyViewModel(player: localPlayer),
                          channelListViewModel: container.makeChannelListViewModel()
                )
            }
        case .dashboard:
            // TODO: DashboardView 연결
            EmptyView()
        case .settings:
            if let localPlayer = players.first {
                SettingsView(viewModel: container.makeSettingsViewModel(player: localPlayer))
            }
        case .gameReady(let localPlayer, let remotePlayer, let isNetwork):
            GameReadyView(viewModel: container.makeGameReadyViewModel(localPlayer: localPlayer,
                                                                      remotePlayer: remotePlayer,
                                                                      isNetwork: isNetwork))
        case .game(let matchPeer, let isNetwork):
            if let myPlayer = players.first {
                let me = PlayerInfo(
                    id: myPlayer.id,
                    role: .local,
                    displayName: myPlayer.nickname,
                    avatar: CharacterAvatar.init(rawValue: myPlayer.character)
                    ?? .character1
                )
                let gameConfig = UserDefaultsList.Settings()
                
                GameView(
                    viewModel: container
                        .makeGameViewModel(localPlayer: me,
                                           remotePlayer: matchPeer,
                                           gameConfig: gameConfig,
                                           isNetwork: isNetwork),
                    videoManager: container.makeVideoManager(isNetwork: isNetwork)
                )
            }
        case .operationGuide(let local, let remote, let isNetwork):
            OperationGuideView(localPlayer: local,
                               remotePlayer: remote,
                               isNetwork: isNetwork)
        case .victoryGuide(let local, let remote, let isNetwork):
            VictoryGuideView(localPlayer: local,
                             remotePlayer: remote,
                             isNetwork: isNetwork)
        case .result:
            // TODO: ResultView 연결
            EmptyView()
        case .testGamePreview:
            TestGamePreviewView(gameConfig: UserDefaultsList.Settings())
        }
    }
}

extension RootView {
    private func handleScenePhase(_ phase: ScenePhase) async {
        switch phase {
        case .active:
            container.explorationCoordinator.setAppActive(true)
        case .inactive, .background:
            container.explorationCoordinator.setAppActive(false)
        @unknown default:
            break
        }
    }

    private func checkUserStatus() {
        guard router.path.isEmpty else { return }
        
        let hasCompletedPermission = UserDefaultsList.Permission.hasCompletedPermissionSetup
        let hasCompletedProfile = UserDefaultsList.Profile.hasCompletedProfileSetup
        
        if hasCompletedProfile {
            router.setRoot(.lobby)
        } else if hasCompletedPermission {
            router.setRoot(.profileSetup)
        } else {
            router.setRoot(.permissionSetup)
        }
    }
}

#Preview {
    RootView()
}
