//
//  SpriteKitPhysicsEngine.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import SpriteKit

final class SpriteKitPhysicsEngine {
    private unowned let scene: SKScene
    private var nodes: [UUID: SKSpriteNode] = [:]
    
    init(scene: SKScene) {
        self.scene = scene
        configureWorld()
        setupGround()
    }
    
    private func configureWorld() {
        // 초당 1200의 가속도가 붙음, 중력 가속도 9.8를 적용하면 너무 미미하기에 화면 비율상 적절한 값을 넣음
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -1200)
    }
    
    private func setupGround() {
        let ground = SKNode()
        ground.position = .zero

        let y: CGFloat = 100

        ground.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: 0, y: y),
            to: CGPoint(x: scene.size.width, y: y)
        )
        ground.physicsBody?.isDynamic = false // 물리 시물레이션 영향을 받지 않도록 설정

        scene.addChild(ground)
    }
    
    func addCharacter(
        id: UUID,
        size: CGSize,
        position: CGPoint
    ) {
        let node = SKSpriteNode(
            color: .systemBlue,
            size: size
        )
        node.position = position

        let body = SKPhysicsBody(rectangleOf: size)
        body.allowsRotation = false // 회전
        body.restitution = 0 // 탄성
        body.friction = 0.8 // 마찰력, 클수록 안미끄러짐
        body.linearDamping = 0.4 // 저항력, 미끄러질때 필요함

        node.physicsBody = body

        nodes[id] = node
        scene.addChild(node)
    }
}
