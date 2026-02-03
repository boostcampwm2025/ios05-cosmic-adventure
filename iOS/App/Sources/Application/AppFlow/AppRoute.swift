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
    case operationGuide(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool)
    case victoryGuide(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool)
    case gameReady(localPlayer: PlayerInfo, remotePlayer: PlayerInfo?, isNetwork: Bool)
    case game(PlayerInfo?, isNetwork: Bool = false) // TODO: 나중에 이름 변경
    case gameResult(display: GameViewModel.GameEndDisplay, localPlayer: PlayerInfo, remotePlayer: PlayerInfo?)

    // Test
    case testGamePreview
}
