//
//  MonsterController.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/12/26.
//

import GameEngineCore
import SpriteKit

final class MonsterController {
    private weak var scene: SKScene?
    private weak var cameraSystem: CameraSystem?
    private(set) var node: SKSpriteNode?
    
    private var sceneSize: CGSize { scene?.size ?? .zero }

    private let riseSpeed: CGFloat = 90
    private let bottomInset: CGFloat = 20   // 화면 안으로 얼마나 보일지
    private let startBelowOffset: CGFloat = 80

    init(scene: SKScene, cameraSystem: CameraSystem) {
        self.scene = scene
        self.cameraSystem = cameraSystem
    }
    
    func setupInitialMonster() {
        guard let scene, let cameraSystem else { return }

        let texture = SKTexture(imageNamed: AppAsset.Image.monsterOverlay.name)
        let sprite = SKSpriteNode(texture: texture)

        // 비율 유지 + 폭 기준
        let tex = texture.size()
        let aspect = (tex.width > 0) ? (tex.height / tex.width) : 0.3
        let w = sceneSize.width
        let h = min(w * aspect, sceneSize.height * 0.25)
        sprite.size = CGSize(width: w, height: h)

        sprite.zPosition = 1
        sprite.name = Constants.Game.NodeName.monster

        let body = SKPhysicsBody(rectangleOf: sprite.size)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.monster.rawValue
        body.contactTestBitMask = PhysicsCategory.player.rawValue
        body.collisionBitMask = 0
        sprite.physicsBody = body

        scene.addChild(sprite)
        self.node = sprite

        resetBelowCamera() // 시작 위치
    }

    func update(deltaTime: TimeInterval) {
        guard let node, let cameraSystem else { return }

        let cameraBottom = cameraSystem.cameraNode.position.y - sceneSize.height / 2
        let maxY = cameraBottom + node.size.height / 2 - bottomInset

        let nextY = node.position.y + riseSpeed * CGFloat(deltaTime)
        node.position.y = min(nextY, maxY)
    }

    func resetBelowCamera() {
        guard let node, let cameraSystem else { return }
        let cameraBottom = cameraSystem.cameraNode.position.y - sceneSize.height / 2
        node.position = CGPoint(x: 0, y: cameraBottom - node.size.height / 2 - startBelowOffset)
    }

    var topY: CGFloat { node?.frame.maxY ?? -.infinity }
}
