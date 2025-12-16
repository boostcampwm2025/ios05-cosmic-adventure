import ARKit

final class FaceGestureController: ObservableObject {
    /// 0.0 ~ 1.0
    @Published private(set) var mouthPucker: Float = 0

    /// roll (radians). 왼쪽 기울임(+), 오른쪽 기울임(-)
    @Published private(set) var headRoll: Float = 0

    /// -1.0 ~ 1.0 (좌 ~ 우)
    @Published private(set) var movementX: Float = 0

    /// 0.0 ~ 1.0 (1회성 이벤트)
    @Published private(set) var jumpIntensity: Float?

    private var wasPuckerOn: Bool = false

    func update(blendShapes: [ARFaceAnchor.BlendShapeLocation: Float], headTransform: simd_float4x4?) {
        mouthPucker = blendShapes[.mouthPucker] ?? 0

        if let headTransform {
            headRoll = extractRoll(from: headTransform)
        } else {
            headRoll = 0
        }

        movementX = computeMoveX(from: headRoll)

        // 점프: threshold를 "넘는 순간"만 트리거
        let puckerOn = mouthPucker > ControlConfig.Threshold.mouthPucker
        if puckerOn && !wasPuckerOn {
            let normalized = (mouthPucker - ControlConfig.Threshold.mouthPucker) / (1 - ControlConfig.Threshold.mouthPucker)
            let intensity = min(max(normalized, 0), 1)
            jumpIntensity = intensity
        }
        wasPuckerOn = puckerOn
    }

    private func computeMoveX(from headRoll: Float) -> Float {
        if abs(headRoll) <= ControlConfig.Threshold.headTiltAngle { return 0 }

        let magnitude = (abs(headRoll) - ControlConfig.Threshold.headTiltAngle) / (ControlConfig.Threshold.headTiltMax - ControlConfig.Threshold.headTiltAngle)
        let intensity = min(max(magnitude, 0), 1)

        // roll이 +면 "왼쪽 기울임"이므로 이동은 - 방향
        return headRoll > 0 ? -intensity : intensity
    }

    func consumeJumpIntensity() -> Float? {
        defer { jumpIntensity = nil }
        return jumpIntensity
    }

    private func extractRoll(from transform: simd_float4x4) -> Float {
        return atan2(transform.columns.0.y, transform.columns.0.x)
    }
}
