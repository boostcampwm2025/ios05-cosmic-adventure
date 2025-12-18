import SpriteKit

/// One-way 플랫폼 노드 (아래에서 위로 통과 가능, 위에서만 착지)
final class PlatformNode: SKSpriteNode {
    init(size: CGSize, color: UIColor = .brown.withAlphaComponent(0.8)) {
        super.init(texture: nil, color: color, size: size)

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = CollisionCategory.platform
        physicsBody?.contactTestBitMask = CollisionCategory.player
        // 초기에는 충돌 비활성화 (GameScene에서 동적으로 제어)
        physicsBody?.collisionBitMask = CollisionCategory.none
        physicsBody?.restitution = PhysicsConstants.restitution
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
