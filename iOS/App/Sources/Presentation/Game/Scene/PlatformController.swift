//
//  PlatformController.swift
//  App
//
//  Created by 영빈 on 1/8/26.
//

import SpriteKit

final class PlatformController {
    private weak var scene: SKScene?
    
    private var lastPlatformY: CGFloat = -100
    private var isNextRight: Bool = true
    private let xOffset: CGFloat = 70
    private let yGap: CGFloat = 130
    
    // Platform indexing
    private var nextPlatformIndex: Int = 0
    private var platformNodesByIndex: [Int: SKSpriteNode] = [:]

    // Player가 마지막으로 밟은(안전) 플랫폼
    private(set) var lastSafePosition: CGPoint = CGPoint(x: 0, y: -150)
    private(set) var lastSafePlatformIndex: Int = 0
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupInitialPlatforms() {
        guard let scene else { return }
        
        let startY: CGFloat = -200
        let startPlatform = createPlatform(
            index: allocateIndex(),
            position: CGPoint(x: 0, y: startY),
            size: CGSize(width: 200, height: 35)
        )
        register(platform: startPlatform)
        scene.addChild(startPlatform)
        
        lastSafePosition = startPlatform.position
        lastSafePlatformIndex = platformIndex(for: startPlatform) ?? 0
        lastPlatformY = startY
        
        for _ in 0..<10 {
            spawnNextPlatform()
        }
        
        // 초기 충돌 설정: 현재 + 다음 플랫폼만 충돌
        updatePlatformCollisions()
    }
    
    func update(cameraY: CGFloat, cullBelowY: CGFloat? = nil) {
        guard let scene else { return }
        
        let sceneHeight = scene.size.height
        let defaultCullLineY = cameraY - (sceneHeight * 2)
        let cullLineY = cullBelowY ?? defaultCullLineY - 100

        scene.enumerateChildNodes(withName: L10N.Game.NodeName.platform) { [weak self] node, _ in
            guard let self else { return }

            // "위험 구간" 아래에 있는 플랫폼을 제거
            if node.position.y < cullLineY && node.position.y < self.lastSafePosition.y {
                if let idx = self.platformIndex(for: node) {
                    self.platformNodesByIndex[idx] = nil
                }
                node.removeFromParent()
            }
        }
        
        // 다음 플랫폼 생성
        let cameraTop = cameraY + sceneHeight / 2
        if lastPlatformY < cameraTop + 100 {
            spawnNextPlatform()
        }
    }
    
    func updateLastSafePlatform(_ platformNode: SKNode) {
        lastSafePosition = platformNode.position
        if let idx = platformIndex(for: platformNode) {
            lastSafePlatformIndex = idx
        }
        updatePlatformCollisions()
    }
    
    func isInCollisionWindow(_ platformNode: SKNode) -> Bool {
        guard let idx = platformIndex(for: platformNode) else { return false }
        let current = lastSafePlatformIndex
        let prev = max(0, current - 1)
        let next = current + 1
        return idx == prev || idx == current || idx == next
    }
    
    func updateCollisions(playerY: CGFloat?, playerDY: CGFloat?) {
        updatePlatformCollisions(playerY: playerY, playerDY: playerDY)
    }
    
    private func spawnNextPlatform() {
        guard let scene else { return }
        
        let nextY = lastPlatformY + yGap
        let nextX: CGFloat = isNextRight ? xOffset : -xOffset
        
        let platform = createPlatform(index: allocateIndex(), position: CGPoint(x: nextX, y: nextY))
        register(platform: platform)
        scene.addChild(platform)
        
        lastPlatformY = nextY
        isNextRight.toggle()
        
        updatePlatformCollisions()
    }
    
    private func createPlatform(index: Int, position: CGPoint, size: CGSize = CGSize(width: 110, height: 35)) -> SKSpriteNode {
        let platform = SKSpriteNode(imageNamed: AppAsset.Image.platform.name)
        platform.name = L10N.Game.NodeName.platform
        platform.size = size
        platform.position = position

        // index 저장
        if platform.userData == nil { platform.userData = [:] }
        platform.userData?["platformIndex"] = index

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.ground.rawValue
        body.restitution = 0.0
        body.friction = 1.0    // 미끄러짐 방지

        // 기본은 충돌 OFF (점프 중 방해 제거)
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player.rawValue

        platform.physicsBody = body
        return platform
    }
    
    private func allocateIndex() -> Int {
        defer { nextPlatformIndex += 1 }
        return nextPlatformIndex
    }

    private func register(platform: SKSpriteNode) {
        if let idx = platformIndex(for: platform) {
            platformNodesByIndex[idx] = platform
        }
    }

    private func platformIndex(for node: SKNode) -> Int? {
        if let n = node.userData?["platformIndex"] as? Int { return n }
        if let n = node.userData?["platformIndex"] as? NSNumber { return n.intValue }
        return nil
    }
    
    private func updatePlatformCollisions(playerY: CGFloat? = nil, playerDY: CGFloat? = nil) {
        let current = lastSafePlatformIndex
        let prev = max(0, current - 1)
        let next = current + 1
        
        func enableAsGround(_ body: SKPhysicsBody) {
            body.categoryBitMask = PhysicsCategory.ground.rawValue
            body.contactTestBitMask = PhysicsCategory.player.rawValue
            body.collisionBitMask = 0
        }
        
        func disableCompletely(_ body: SKPhysicsBody) {
            body.categoryBitMask = 0
            body.contactTestBitMask = PhysicsCategory.player.rawValue
            body.collisionBitMask = 0
        }
        
        for (idx, node) in platformNodesByIndex {
            guard let body = node.physicsBody else { continue }
            
            switch idx {
            case current:
                // 현재 플랫폼은 항상 활성
                enableAsGround(body)
                node.alpha = 1.0
            case prev:
                // 이전 플랫폼은 항상 활성(뒤로 이동/실수 대비)
                enableAsGround(body)
            case next:
                // 바로 다음 플랫폼 활성화
                enableAsGround(body)
                node.alpha = 1.0
                
            default:
                disableCompletely(body)
                node.alpha = 0.5
            }
        }
    }
}
