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
        // AppRouter 기본값이 .permissionSetup이므로, 비동기 checkUserStatus()가 올바른 root를 설정하기 전에
        // SwiftUI가 첫 프레임을 렌더링하면 PermissionSetupView가 한 프레임 깜빡임.
        // 이를 방지하기 위해 UserDefaults를 동기적으로 읽어 init 시점에 올바른 초기 라우트를 결정.
        let initialRouter = router ?? AppRouter(initial: Self.initialRootRoute())
        _router = State(initialValue: initialRouter)
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
            } else {
                 // SwiftData @Query가 아직 로딩 중이면 players.first가 nil이므로,
                 // 빈 화면 대신 로고 placeholder를 표시하여 깜빡임 방지.
                 playerLoadingView
             }
        case .dashboard:
            // TODO: DashboardView 연결
            EmptyView()
        case .settings:
            if let localPlayer = players.first {
                SettingsView(viewModel: container.makeSettingsViewModel(player: localPlayer))
            } else {
                 // SwiftData @Query가 아직 로딩 중이면 players.first가 nil이므로,
                 // 빈 화면 대신 로고 placeholder를 표시하여 깜빡임 방지.
                 playerLoadingView
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
            } else {
                // SwiftData @Query가 아직 로딩 중이면 players.first가 nil이므로,
                // 빈 화면 대신 로고 placeholder를 표시하여 깜빡임 방지.
                playerLoadingView
            }
        case .operationGuide(let local, let remote, let isNetwork):
            OperationGuideView(localPlayer: local,
                               remotePlayer: remote,
                               isNetwork: isNetwork)
        case .victoryGuide(let local, let remote, let isNetwork):
            VictoryGuideView(localPlayer: local,
                             remotePlayer: remote,
                             isNetwork: isNetwork)
        case .gameResult(let display, let localPlayer, let remotePlayer):
            GameResultView(display: display, localPlayer: localPlayer, remotePlayer: remotePlayer)
        case .testGamePreview:
            TestGamePreviewView(gameConfig: UserDefaultsList.Settings())
        }
    }
}

extension RootView {
     /// UserDefaults를 동기적으로 읽어 초기 라우트를 결정한다.
     /// RootView.init에서 사용하여 첫 프레임부터 올바른 화면을 렌더링한다.
     private static func initialRootRoute() -> AppRoute {
        let hasCompletedPermission = UserDefaultsList.Permission.hasCompletedPermissionSetup
        let hasCompletedProfile = UserDefaultsList.Profile.hasCompletedProfileSetup

        if hasCompletedProfile {
            return .lobby
        }
        if hasCompletedPermission {
            return .profileSetup
        }
        return .permissionSetup
    }

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

     /// 앱이 foreground로 돌아올 때 라우트를 재확인한다.
     /// initialRootRoute()가 init에서 이미 올바른 root를 설정하므로,
     /// 여기서는 root가 변경된 경우(예: 설정 완료 후)에만 업데이트한다.
     private func checkUserStatus() {
        guard router.path.isEmpty else { return }

        let desiredRoot = Self.initialRootRoute()
        guard router.root != desiredRoot else { return }
        router.setRoot(desiredRoot)
    }

    /// SwiftData @Query 로딩이 완료되기 전에 표시되는 placeholder.
    /// players.first가 nil인 동안 빈 화면 대신 이 뷰를 보여준다.
    private var playerLoadingView: some View {
        BackgroundContainerView {
            LoadingPlaceholderView()
        }
    }
}

#Preview {
    RootView()
}
