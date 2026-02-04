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

    private let bottomInset: CGFloat = 20

    private let startBelowOffset: CGFloat = 80

    init(scene: SKScene, cameraSystem: CameraSystem) {
        self.scene = scene
        self.cameraSystem = cameraSystem
    }
    
    func setupInitialMonster() {
        guard let scene else { return }

        let textures = loadMonsterTextures()
        let texture = textures.first ?? SKTexture(imageNamed: AppAsset.Image.monsterOverlay.name)
        let sprite = SKSpriteNode(texture: texture)

        // 비율 유지 + 폭 기준
        let tex = texture.size()
        let aspect = (tex.width > 0) ? (tex.height / tex.width) : 0.3
        let w = sceneSize.width
        let h = min(w * aspect, sceneSize.height * 0.25)
        sprite.size = CGSize(width: w, height: h)

        sprite.zPosition = 1
        sprite.name = L10N.Game.NodeName.monster

        let body = SKPhysicsBody(rectangleOf: sprite.size)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.monster.rawValue
        body.contactTestBitMask = PhysicsCategory.playerMe.rawValue
        body.collisionBitMask = 0
        sprite.physicsBody = body

        scene.addChild(sprite)
        self.node = sprite

        attachMonsterAnimation(to: sprite, textures: textures)
        resetBelowCamera() // 시작 위치
    }

    func update(deltaTime: TimeInterval, platformTopY: CGFloat?) {
        guard let node, let cameraSystem else { return }

        let cameraBottom = cameraSystem.cameraNode.position.y - sceneSize.height / 2
        // 카메라 바닥 기준 제한
        let cameraLimitTopY = cameraBottom + node.size.height / 2
        // 플랫폼과 겹치지 않도록 제한
        let platformLimitTopY: CGFloat

        if let platformTopY {
            platformLimitTopY = platformTopY - node.size.height / 2 - bottomInset
        } else {
            platformLimitTopY = .greatestFiniteMagnitude
        }

        let limitTopY = min(cameraLimitTopY, platformLimitTopY)
        // topY 제한을 centerY 제한으로 변환
        let maxCenterY = limitTopY
        let nextY = node.position.y + riseSpeed * CGFloat(deltaTime)

        node.position.y = min(nextY, maxCenterY)
    }

    func resetBelowCamera() {
        guard let node, let cameraSystem else { return }
        let cameraBottom = cameraSystem.cameraNode.position.y - sceneSize.height / 2
        node.position = CGPoint(x: 0, y: cameraBottom - node.size.height / 2 - startBelowOffset)
    }

    var topY: CGFloat { node?.frame.maxY ?? -.infinity }
}

private extension MonsterController {
    func attachMonsterAnimation(to sprite: SKSpriteNode, textures: [SKTexture]) {
        guard textures.count >= 2 else { return }
        let animate = SKAction.animate(with: textures, timePerFrame: 0.08, resize: false, restore: true)
        sprite.run(.repeatForever(animate), withKey: "monsterAnimation")
    }

    func loadMonsterTextures() -> [SKTexture] {
        let atlasName = GameSpriteAsset.monster.atlasName
        guard !atlasName.isEmpty else { return [] }
        let atlas = SKTextureAtlas(named: atlasName)
        let names = atlas.textureNames.sorted { lhs, rhs in
            extractFrameIndex(from: lhs) < extractFrameIndex(from: rhs)
        }
        let forward = names.map { atlas.textureNamed($0) }
        guard forward.count >= 2 else { return forward }
        let backward = forward.dropLast().dropFirst().reversed()
        return forward + backward
    }

    func extractFrameIndex(from name: String) -> Int {
        let digits = name.compactMap { $0.isNumber ? $0 : nil }
        let value = String(digits)
        return Int(value) ?? 0
    }
}
