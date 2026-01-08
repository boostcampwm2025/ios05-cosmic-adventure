//
//  RootView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

import SwiftUI

struct RootView: View {
    @StateObject var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            screen(router.root)
                .navigationDestination(for: AppRoute.self) { route in
                    screen(route)
                }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    func screen(_ route: AppRoute) -> some View {
        switch route {
        case .permissionSetup:
            PermissionSetupView()
        case .profileSetup:
            ProfileSetupView()
        case .home:
            LobbyView()
        case .dashboard:
            // TODO: DashboardView 연결
            EmptyView()
        case .settings:
            // TODO: SettingsView 연결
            EmptyView()
        case .game:
            // TODO: GameView 연결
            EmptyView()
        case .result:
            // TODO: ResultView 연결
            EmptyView()
        }
    }
}

#Preview {
    RootView()
}
