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
    public func applyState(
        deltaTime: TimeInterval,
        moveX: Double,
        isGrounded: Bool,
        targetPosition: CGPoint? = nil
    ) {
        // X축 이동
        applyMovement(moveX: moveX, isGrounded: isGrounded)

        // Y축 중력 보정 (Apex Control)
        applyGravityCorrection(deltaTime: deltaTime, isGrounded: isGrounded)

        // 원격 위치 동기화 보정(속도 기반)
        if let targetPosition {
            applyNetworkPositionCorrection(targetPosition, deltaTime: deltaTime)
        }
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

        let curvedInput = applyCurve(to: moveX)
        let targetVelocityX = CGFloat(curvedInput) * PhysicsConstants.moveSpeed
        let currentDx = body.velocity.dx
        let hasInput = abs(moveX) > PhysicsConstants.inputThreshold // 입력이 아주 조금이라도 있는지 확인
        let isTurning = (moveX > 0 && currentDx < -10) || (moveX < 0 && currentDx > 10)

        if isGrounded && !hasInput {
            // 부드러운 감속: 즉시 정지 시 입력 노이즈로 인한 미세 떨림 방지
            let newDx = CGFloat.lerp(start: currentDx, end: 0, t: PhysicsConstants.groundDeceleration)
            // 속도가 충분히 낮으면 완전 정지
            body.velocity = CGVector(dx: abs(newDx) < 5 ? 0 : newDx, dy: body.velocity.dy)
        } else {
            // 공중이거나 입력이 있을 때
            let acceleration: CGFloat
            if isGrounded {
                if isTurning {
                    acceleration = PhysicsConstants.groundTurnAcceleration
                } else {
                    acceleration = hasInput
                        ? PhysicsConstants.groundAcceleration
                        : PhysicsConstants.groundDeceleration
                }
            } else {
                if isTurning {
                    acceleration = PhysicsConstants.airTurnAcceleration
                } else {
                    acceleration = hasInput
                        ? PhysicsConstants.airAcceleration
                        : PhysicsConstants.airDeceleration
                }
            }

            let newDx = CGFloat.lerp(start: currentDx, end: targetVelocityX, t: acceleration)
            body.velocity = CGVector(dx: newDx, dy: body.velocity.dy)
        }
    }
    
    private func applyCurve(to input: Double) -> Double {
        let sign = input >= 0 ? 1.0 : -1.0
        let absInput = abs(input)
        let curved = pow(absInput, Double(PhysicsConstants.inputCurveExponent))
        return sign * curved
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

    private func applyNetworkPositionCorrection(_ targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard let body,
              let node = body.node,
              deltaTime > 0 else { return }

        let current = node.position
        let dx = targetPosition.x - current.x
        let dy = targetPosition.y - current.y
        let distance = hypot(dx, dy)

        if distance <= PhysicsConstants.networkSyncDeadZone {
            return
        }

        // 비정상적으로 크게 벌어진 경우에만 안전 스냅
        if distance >= PhysicsConstants.networkSyncEmergencySnapDistance {
            node.position = targetPosition
            body.velocity = .zero
            return
        }

        let gainT = min(max(distance / PhysicsConstants.networkSyncGainDistance, 0), 1)
        let gain = CGFloat.lerp(
            start: PhysicsConstants.networkSyncMinCorrectionGain,
            end: PhysicsConstants.networkSyncMaxCorrectionGain,
            t: gainT
        )

        let desiredVx = dx * gain
        let desiredVy = dy * gain
        let maxSpeed = PhysicsConstants.networkSyncMaxCorrectionSpeed

        let correctionVx = clamp(desiredVx, min: -maxSpeed, max: maxSpeed)
        let correctionVy = clamp(desiredVy, min: -maxSpeed, max: maxSpeed)

        body.velocity = CGVector(
            dx: body.velocity.dx + correctionVx * CGFloat(deltaTime),
            dy: body.velocity.dy + correctionVy * CGFloat(deltaTime)
        )
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        min(maxValue, max(minValue, value))
    }
}
