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
    case game(String?) // TODO: 나중에 ID나 nickname 둘 중 하나로 통일
    case operationGuide(me: LobbyExplorer, peer: LobbyExplorer?)
    case victoryGuide(me: LobbyExplorer, peer: LobbyExplorer?)
    case result
}
