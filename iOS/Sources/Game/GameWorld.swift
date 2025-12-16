//
//  GameWorld.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import Foundation

final class GameWorld {

    private let engine: SpriteKitPhysicsEngine // TODO: 추상화
    private let characterID: UUID

    init(
        engine: SpriteKitPhysicsEngine,
        mapSize: CGSize,
        characterSize: CGSize = CGSize(width: 50, height: 50)
    ) {
        self.engine = engine
        self.characterID = UUID()

        engine.addCharacter(
            id: characterID,
            size: characterSize,
            position: CGPoint(
                x: mapSize.width / 2,
                y: mapSize.height / 2
            )
        )
    }
}

