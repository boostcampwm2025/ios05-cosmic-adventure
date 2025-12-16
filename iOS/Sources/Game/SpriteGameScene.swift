//
//  SpriteGameScene.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import SpriteKit

final class SpriteGameScene: SKScene {
    
    private let characterNode = SKSpriteNode(
        color: .systemBlue,
        size: CGSize(width: 50, height: 50)
    )
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupCharacter()
    }
    
    private func setupCharacter() {
        characterNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        addChild(characterNode)
    }
    
    func handle(_ event: GameEvent) {
        switch event {
        case .moveLeft(let strength):
            moveHorizontally(by: -strength)

        case .moveRight(let strength):
            moveHorizontally(by: strength)

        case .jump(let strength):
            jump(with: strength)
        }
    }
    
    private func moveHorizontally(by strength: Double) {
        characterNode.position.x += CGFloat(strength * 30)
    }

    private func jump(with strength: Double) {
        let action = SKAction.moveBy(
            x: 0,
            y: CGFloat(strength * 200),
            duration: 0.2
        )
        characterNode.run(action)
    }
}
