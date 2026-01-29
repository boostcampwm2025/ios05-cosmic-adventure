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
    case gameReady(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool)
    case game(PlayerInfo?, isNetwork: Bool = false) // TODO: 나중에 이름 변경
    case operationGuide(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool)
    case victoryGuide(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool)
    case result
    
    // Test
    case testGamePreview
}
