import SpriteKit

class PlatformNode: SKSpriteNode {
    
    init(position: CGPoint) {
        super.init(texture: nil, color: .brown, size: GameConfig.Platform.size)
        self.position = position
        
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false // 고정된 물체
        physicsBody?.categoryBitMask = PhysicsCategory.platform
        physicsBody?.contactTestBitMask = PhysicsCategory.character
        physicsBody?.collisionBitMask = PhysicsCategory.character
        physicsBody?.friction = 0.5
    }
}
