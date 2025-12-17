//
//  SpriteKitPhysicsEngine.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import SpriteKit

final class SpriteKitPhysicsEngine: PhysicsEngine {
    private unowned let scene: SKScene
    private var nodes: [UUID: SKSpriteNode] = [:]
    
    init(scene: SKScene) {
        self.scene = scene
        configureWorld()
        setupGround()
    }
    
    private func configureWorld() {
        // 중력 가속도 9.8를 적용
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
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
    
    func apply(_ command: CharacterCommand, to id: UUID) {
        guard let body = nodes[id]?.physicsBody else { return }

        switch command {
        case .moveLeft(let strength):
            body.velocity.dx = -strength * 400

        case .moveRight(let strength):
            body.velocity.dx = strength * 400

        case .jump(let strength):
            body.velocity.dy = strength * 600
        }
    }
    
    // 찾고자하는 노드 상태값 가져오기
    func characterState(id: UUID) -> CharacterState {
        guard
            let node = nodes[id],
            let body = node.physicsBody
        else {
            return CharacterState(
                position: .zero,
                velocity: .zero,
                isGrounded: false
            )
        }

        let isGrounded = abs(body.velocity.dy) < 1.0 // 속력이 1미만일 때 바닥으로 생각

        return CharacterState(
            position: node.position,
            velocity: body.velocity,
            isGrounded: isGrounded
        )
    }
}
