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
    
    private(set) var lastSafePosition: CGPoint = CGPoint(x: 0, y: -150)
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupInitialPlatforms() {
        guard let scene else { return }
        
        let startY: CGFloat = -200
        let startPlatform = createPlatform(
            position: CGPoint(x: 0, y: startY),
            size: CGSize(width: 200, height: 35)
        )
        scene.addChild(startPlatform)
        
        lastSafePosition = startPlatform.position
        lastPlatformY = startY
        
        for _ in 0..<10 {
            spawnNextPlatform()
        }
    }
    
    func update(cameraY: CGFloat, sceneHeight: CGFloat) {
        guard let scene else { return }
        
        let cameraTop = cameraY + sceneHeight / 2
        if lastPlatformY < cameraTop + 100 {
            spawnNextPlatform()
        }
        
        let cameraBottom = cameraY - (sceneHeight * 2)
        scene.enumerateChildNodes(withName: Constants.Game.NodeName.platform) { [weak self] node, _ in
            guard let self else { return }
            if node.position.y < cameraBottom && node.position.y < self.lastSafePosition.y {
                node.removeFromParent()
            }
        }
    }
    
    func updateLastSafePosition(_ position: CGPoint) {
        lastSafePosition = position
    }
    
    private func spawnNextPlatform() {
        guard let scene else { return }
        
        let nextY = lastPlatformY + yGap
        let nextX: CGFloat = isNextRight ? xOffset : -xOffset
        
        let platform = createPlatform(position: CGPoint(x: nextX, y: nextY))
        scene.addChild(platform)
        
        lastPlatformY = nextY
        isNextRight.toggle()
    }
    
    private func createPlatform(position: CGPoint, size: CGSize = CGSize(width: 110, height: 35)) -> SKSpriteNode {
        let platform = SKSpriteNode(imageNamed: AppAsset.Image.platform.name)
        platform.name = Constants.Game.NodeName.platform
        platform.size = size
        platform.position = position
        platform.physicsBody = SKPhysicsBody(rectangleOf: size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        platform.physicsBody?.restitution = 0.0
        return platform
    }
}
