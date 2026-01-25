//
//  GameSpriteAsset.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/26/26.
//

enum GameSpriteAsset: String, Codable, CaseIterable, Equatable {
    case platform
    case monster
    case goalRocket

    var name: String {
        switch self {
        case .platform:
            return AppAsset.Image.platform.name
        case .monster:
            return AppAsset.Image.monsterOverlay.name
        case .goalRocket:
            return AppAsset.Image.goalRocket.name
        }
    }

    var atlasName: String {
        switch self {
        case .goalRocket:
            return "GoalRocket"
        default:
            return ""
        }
    }
}
