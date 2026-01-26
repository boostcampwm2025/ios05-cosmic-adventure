//
//  RootView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

import SwiftUI
import StorageKit

struct RootView: View {
    private let viewModelFactory: ViewModelFactory
    @State var router: AppRouter
    @Query private var players: [Player]

    init(container: AppContainer? = nil, router: AppRouter? = nil) {
        self.viewModelFactory = container ?? AppContainer()
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
    }

    @ViewBuilder
    func screen(_ route: AppRoute) -> some View {
        switch route {
        case .permissionSetup:
            PermissionSetupView(viewModel: viewModelFactory.makePermissionSetupViewModel())
        case .profileSetup:
            ProfileSetupView(viewModel: viewModelFactory.makeProfileSetupViewModel())
        case .lobby:
            if let myPlayer = players.first {
                LobbyView(viewModel:
                            viewModelFactory.makeLobbyViewModel(playerId: myPlayer.id,
                                                                nickname: myPlayer.nickname,
                                                                characterType: myPlayer.character),
                          channelListViewModel: viewModelFactory.makeChannelListViewModel()
                )
            }
        case .dashboard:
            // TODO: DashboardView 연결
            EmptyView()
        case .settings:
            if let player = players.first {
                SettingsView(viewModel: viewModelFactory.makeSettingsViewModel(player: player))
            }
        case .gameReady(let me, let peer):
             GameReadyView(viewModel: viewModelFactory.makeGameReadyViewModel(me: me, peer: peer))
        case .game(let matchPeer, let isNetwork):
            if let myPlayer = players.first {
                let me = PlayerInfo(
                    id: myPlayer.id,
                    role: .me,
                    displayName: myPlayer.nickname,
                    avatar: CharacterAvatar.init(rawValue: myPlayer.character)
                    ?? .character1
                )
                let gameConfig = UserDefaultsList.Settings()
                
                GameView(
                    viewModel: viewModelFactory
                        .makeGameViewModel(localPlayer: me, remotePlayer: matchPeer, gameConfig: gameConfig, isNetwork: isNetwork),
                    videoManager: viewModelFactory.makeVideoManager()
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
        let hasPlayerInfo = !players.isEmpty

        if hasPlayerInfo {
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
