//
//  AppRouter.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

import Observation

@MainActor
@Observable
final class AppRouter {
    var root: AppRoute
    var path: [AppRoute]

    init(initial: AppRoute = .permissionSetup) {
        self.root = initial
        self.path = []
    }

    // MARK: - Navigation
    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func popTo(_ route: AppRoute) {
        guard route != root else {
            popToRoot()
            return
        }
        
        guard let idx = path.lastIndex(of: route) else { return }
        path = Array(path.prefix(through: idx))
    }

    // MARK: - Root
    func setRoot(_ route: AppRoute) {
        root = route
        path.removeAll()
    }

    func resetToHome() {
        setRoot(.home)
    }
}
