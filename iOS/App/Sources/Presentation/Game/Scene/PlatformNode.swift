//
//  PlatformNode.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

import SpriteKit

// 발판 노드
final class PlatformNode: SKSpriteNode {
    init(position: CGPoint, size: CGSize = CGSize(width: 100, height: 20)) {
        super.init(texture: nil, color: .brown, size: size)

        self.position = position
        self.name = Constants.Game.NodeName.platform

        // 받아온 size에 맞춰서 물리 바디 생성 (자동으로 크기 맞춰짐)
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        self.physicsBody?.friction = 1.0    // 미끄러짐 방지
        self.physicsBody?.restitution = 0.0 // 튀어오름 방지
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
