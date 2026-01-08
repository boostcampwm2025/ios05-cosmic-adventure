//
//  RootView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

import SwiftUI

struct RootView: View {
    private let viewModelFactory: ViewModelFactory
    @State var router: AppRouter

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
    }

    @ViewBuilder
    func screen(_ route: AppRoute) -> some View {
        switch route {
        case .permissionSetup:
            PermissionSetupView(viewModel: viewModelFactory.makePermissionSetupViewModel())
        case .profileSetup:
            ProfileSetupView(viewModel: viewModelFactory.makeProfileSetupViewModel())
        case .lobby:
            LobbyView(viewModel: viewModelFactory.makeLobbyViewModel())
        case .dashboard:
            // TODO: DashboardView 연결
            EmptyView()
        case .settings:
            // TODO: SettingsView 연결
            EmptyView()
        case .game:
            GameView()
        case .result:
            // TODO: ResultView 연결
            EmptyView()
        }
    }
}

#Preview {
    RootView()
}
