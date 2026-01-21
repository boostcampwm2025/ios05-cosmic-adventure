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
        .onAppear {
            self.checkUserStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            container.explorationCoordinator.setAppActive(newPhase == .active)
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
            if let myExplorer = players.first {
                LobbyView(viewModel:
                            container.makeLobbyViewModel(nickname: myExplorer.nickname,
                                                                characterType: myExplorer.character),
                          channelListViewModel: container.makeChannelListViewModel()
                )
            }
        case .dashboard:
            // TODO: DashboardView 연결
            EmptyView()
        case .settings:
            if let player = players.first {
                SettingsView(viewModel: container.makeSettingsViewModel(player: player))
            }
        case .gameReady(let me, let peer):
            GameReadyView(viewModel: container.makeGameReadyViewModel(me: me, peer: peer))
        case .game(let matchPeer, let isNetwork):
            if let myExplorer = players.first {
                let me = LobbyExplorer(
                    role: .me,
                    displayName: myExplorer.nickname,
                    avatar: CharacterAvatar.init(rawValue: myExplorer.character)
                    ?? .character1
                )
                let gameConfig = UserDefaultsList.Settings()
                
                GameView(
                    viewModel: container
                        .makeGameViewModel(me: me, matchPeer: matchPeer, gameConfig: gameConfig, isNetwork: isNetwork),
                    videoManager: container.makeVideoManager()
                )
            }
        case .operationGuide(let me, let peer, let isNetwork):
            OperationGuideView(me: me, peer: peer, isNetwork: isNetwork)
        case .victoryGuide(let me, let peer, let isNetwork):
            VictoryGuideView(me: me, peer: peer, isNetwork: isNetwork)
        case .result:
            // TODO: ResultView 연결
            EmptyView()
        }
    }
}

extension RootView {
    private func checkUserStatus() {
        let hasCompletedPermission = UserDefaultsList.Permission.hasCompletedPermissionSetup
        let hasPlayerProfile = !players.isEmpty

        if hasPlayerProfile {
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
