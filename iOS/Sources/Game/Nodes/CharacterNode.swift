import SpriteKit

class CharacterNode: SKSpriteNode {

    private var jumpCount: Int = 0
    private var isGrounded: Bool = true

    init() {
        // 임시로 파란색 원으로 표시
        super.init(texture: nil, color: .blue, size: CGSize(width: GameConfig.Physics.characterRadius * 2, height: GameConfig.Physics.characterRadius * 2))

        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: GameConfig.Physics.characterRadius)
        physicsBody?.categoryBitMask = PhysicsCategory.character
        physicsBody?.contactTestBitMask = PhysicsCategory.platform | PhysicsCategory.boundary
        physicsBody?.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.boundary
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = GameConfig.Physics.characterRestitution
        physicsBody?.friction = GameConfig.Physics.characterFriction
    }
    
    func jump(intensity: CGFloat) {
        guard jumpCount < GameConfig.Physics.maxJumpCount else { return }

        let clampedIntensity = min(max(intensity, 0), 1)
        let impulse = GameConfig.Physics.minJumpImpulse + (GameConfig.Physics.maxJumpImpulse - GameConfig.Physics.minJumpImpulse) * clampedIntensity

        jumpCount += 1
        isGrounded = false

        physicsBody?.velocity = CGVector(dx: physicsBody?.velocity.dx ?? 0, dy: 0) // 수직 속도 초기화
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: impulse))
    }

    func resetJumpCount() {
        jumpCount = 0
        isGrounded = true
    }
    
    func move(intensity: CGFloat) {
        // intensity: -1.0 ~ 1.0 (좌 ~ 우)
        let magnitude = min(max(abs(intensity), 0), 1)
        guard magnitude > 0 else {
            // 입력이 없으면 즉시 정지하지 말고 지상/공중에 따라 감속
            let currentDX = physicsBody?.velocity.dx ?? 0
            let decel = isGrounded ? GameConfig.Physics.groundDeceleration : GameConfig.Physics.airDeceleration
            let nextDX = currentDX * decel
            physicsBody?.velocity.dx = abs(nextDX) < GameConfig.Physics.idleMoveStopThreshold ? 0 : nextDX
            return
        }

        // 임계각을 넘긴 순간부터 최소 속도 보장
        let speed = GameConfig.Physics.minMoveSpeed + (GameConfig.Physics.maxMoveSpeed - GameConfig.Physics.minMoveSpeed) * magnitude
        let sign: CGFloat = intensity >= 0 ? 1 : -1

        physicsBody?.velocity.dx = speed * sign
    }
}
