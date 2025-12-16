//
//  SpriteGameScene.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import SpriteKit

final class SpriteGameScene: SKScene {
    
    private var world: GameWorld!

    private let characterNode = SKSpriteNode(
        color: .systemBlue,
        size: CGSize(width: 50, height: 50)
    )
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        size = view.bounds.size

        let engine = SpriteKitPhysicsEngine(scene: self)
        world = GameWorld(
            engine: engine,
            mapSize: size
        )
    }
    
    func handle(_ command: CharacterCommand) {
        world.handle(command)
    }
}
