//
//  PhysicsCore.swift
//  GameEngineCore
//
//  Created by soyoung on 1/7/26.
//

import SpriteKit

public final class PhysicsCore {
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
    }

    // 매 프레임 호출: State -> Velocity 적용
    public func applyState(deltaTime: TimeInterval, moveX: Double, isGrounded: Bool) {
        // X축 이동
        applyMovement(moveX: moveX, isGrounded: isGrounded)

        // Y축 중력 보정 (Apex Control)
        applyGravityCorrection(deltaTime: deltaTime, isGrounded: isGrounded)
    }

    // 즉발적인 점프 힘 적용
    public func applyJumpImpulse() {
        guard let body = body else { return }
        // 기존 Y속도 초기화 후 점프 (반응성 향상)
        body.velocity = CGVector(dx: body.velocity.dx, dy: 0)
        body.applyImpulse(CGVector(dx: 0, dy: PhysicsConstants.jumpImpulse))
    }

    private func applyMovement(moveX: Double, isGrounded: Bool) {
        guard let body = body else { return }

        let targetVelocityX = CGFloat(moveX) * PhysicsConstants.moveSpeed
        let currentDx = body.velocity.dx
        let hasInput = abs(moveX) > PhysicsConstants.inputThreshold // 입력이 아주 조금이라도 있는지 확인

        // 땅에 있고(isGrounded), 입력이 없으면(!hasInput) -> 강제 정지
        if isGrounded && !hasInput {
            // 미끄러짐 방지: X축 속도를 아예 0으로 고정
            body.velocity = CGVector(dx: 0, dy: body.velocity.dy)
        } else {
            // 공중이거나 입력이 있을 때
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

            let newDx = CGFloat.lerp(start: currentDx, end: targetVelocityX, t: acceleration)
            body.velocity = CGVector(dx: newDx, dy: body.velocity.dy)
        }
    }

    private func applyGravityCorrection(deltaTime: TimeInterval, isGrounded: Bool) {
        guard let body = body else { return }
        let velocityY = body.velocity.dy

        let isAtApex = abs(velocityY) < PhysicsConstants.apexThreshold && !isGrounded
        let isFalling = velocityY < 0

        let multiplier: CGFloat
        if isAtApex {
            multiplier = PhysicsConstants.apexGravityMultiplier
        } else if isFalling {
            multiplier = PhysicsConstants.fallGravityMultiplier
        } else {
            multiplier = 1.0
        }

        let additionalGravity = PhysicsConstants.gravityDY * (multiplier - 1.0) * CGFloat(deltaTime)
        body.velocity = CGVector(dx: body.velocity.dx, dy: velocityY + additionalGravity)
    }
}
