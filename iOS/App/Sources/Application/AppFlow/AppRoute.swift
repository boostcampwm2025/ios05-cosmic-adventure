//
//  AppRoute.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

enum AppRoute: Hashable {
    // Onboarding
    case permissionSetup
    case profileSetup

    // Main
    case lobby
    case settings
    case dashboard

    // Game
    case gameReady(me: LobbyExplorer, peer: LobbyExplorer)
    case game(LobbyExplorer?, isNetwork: Bool = false) // TODO: 나중에 이름 변경
    case operationGuide(me: LobbyExplorer, peer: LobbyExplorer?, isNetwork: Bool)
    case victoryGuide(me: LobbyExplorer, peer: LobbyExplorer?, isNetwork: Bool)
    case result
}
