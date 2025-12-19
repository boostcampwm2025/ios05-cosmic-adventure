import SpriteKit

/// SpriteKit 물리 바디를 제어하는 컨트롤러
/// - 지상/공중 이동 분리
/// - Apex(점프 정점) 체공 처리
public final class PhysicsController {
    private weak var body: SKPhysicsBody?
    
    /// 착지 상태 (외부에서 설정)
    public var isGrounded: Bool = false

    public init(body: SKPhysicsBody) {
        self.body = body
        configureBody()
    }

    private func configureBody() {
        guard let body = body else { return }

        body.allowsRotation = false
        body.linearDamping = PhysicsConstants.linearDamping
        body.friction = PhysicsConstants.friction
        body.restitution = PhysicsConstants.restitution
    }

    /// 이동 의도 적용 (moveX: -1.0 ~ 1.0)
    /// 지상에서는 민첩하게, 공중에서는 관성 있게
    public func applyMovement(moveX: Double) {
        guard let body = body else { return }

        let targetVelocityX = CGFloat(moveX) * PhysicsConstants.moveSpeed
        let currentDx = body.velocity.dx
        let hasInput = abs(moveX) > 0.01
        
        // 지상 vs 공중 가속/감속 분리
        let acceleration: CGFloat
        if isGrounded {
            acceleration = hasInput
                ? PhysicsConstants.groundAcceleration
                : PhysicsConstants.groundDeceleration
        } else {
            acceleration = hasInput
                ? PhysicsConstants.airAcceleration
                : PhysicsConstants.airDeceleration
        }
        
        let newDx = lerp(currentDx, targetVelocityX, acceleration)
        body.velocity = CGVector(dx: newDx, dy: body.velocity.dy)
    }

    /// 점프 적용
    public func jump() {
        guard let body = body else { return }

        // 기존 Y 속도 초기화 후 점프 (반응성 향상)
        body.velocity = CGVector(dx: body.velocity.dx, dy: 0)
        body.applyImpulse(CGVector(dx: 0, dy: PhysicsConstants.jumpImpulse))
    }
    
    /// 매 프레임 호출: Apex 체공 + 하강 가속 처리
    public func updateGravity() {
        guard let body = body else { return }
        
        let velocityY = body.velocity.dy
        let baseGravity = PhysicsConstants.gravityDY
        
        // Apex 판정: 속도가 작을 때 (점프 정점 부근)
        let isAtApex = abs(velocityY) < PhysicsConstants.apexThreshold && !isGrounded
        // 하강 중
        let isFalling = velocityY < 0
        
        let gravityMultiplier: CGFloat
        if isAtApex {
            // 정점에서 체공감
            gravityMultiplier = PhysicsConstants.apexGravityMultiplier
        } else if isFalling {
            // 하강 시 빠르게
            gravityMultiplier = PhysicsConstants.fallGravityMultiplier
        } else {
            // 상승 중
            gravityMultiplier = 1.0
        }
        
        // 추가 중력 적용 (기본 중력 * (배율 - 1))
        // 기본 중력은 physicsWorld에서 적용되므로, 차이만큼만 추가
        let additionalGravity = baseGravity * (gravityMultiplier - 1.0)
        body.velocity = CGVector(
            dx: body.velocity.dx,
            dy: body.velocity.dy + additionalGravity
        )
    }
}
