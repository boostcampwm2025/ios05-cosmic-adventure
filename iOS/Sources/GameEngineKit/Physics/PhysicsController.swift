import SpriteKit

// - NOTE: CharacterState는 Gameplay 모듈에 있으므로, GameEngineKit이 Gameplay를 알아야 쓸 수 있음.
// 하지만 GameEngineKit은 '엔진'이라 'Gameplay(비즈니스 룰)'를 모르는 게 의존성 방향상 깔끔함.
// -> 그래서 PhysicsController는 CharacterState(구조체) 대신, 필요한 값(moveX)만 인자로 받는 게 더 범용적임.

/// SpriteKit 물리 바디를 제어하는 컨트롤러
public final class PhysicsController {
    private weak var body: SKPhysicsBody?

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

        // 카테고리 설정 (기본값: 플레이어)
        // 실제로는 외부에서 노드 생성 시 설정하거나, 여기서 init 인자로 받을 수도 있음.
        // 일단 기본 물리 속성만 설정.
    }

    /// 이동 의도 적용 (moveX: -1.0 ~ 1.0)
    public func applyMovement(moveX: Double) {
        guard let body = body else { return }

        let targetVelocityX = CGFloat(moveX) * PhysicsConstants.moveSpeed

        // 부드러운 가속
        let currentDx = body.velocity.dx
        let newDx = lerp(currentDx, targetVelocityX, PhysicsConstants.movementSmoothing)

        body.velocity = CGVector(dx: newDx, dy: body.velocity.dy)
    }

    /// 점프 적용
    public func jump() {
        guard let body = body else { return }

        // 기존 Y 속도 초기화 후 점프 (반응성 향상)
        body.velocity = CGVector(dx: body.velocity.dx, dy: 0)
        body.applyImpulse(CGVector(dx: 0, dy: PhysicsConstants.jumpImpulse))
    }
}
