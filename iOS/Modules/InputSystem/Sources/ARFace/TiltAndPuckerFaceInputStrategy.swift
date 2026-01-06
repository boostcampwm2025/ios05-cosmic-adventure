//
//  TiltAndPuckerFaceInputStrategy.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import ARKit

public final class TiltAndPuckerFaceInputStrategy: FaceInputStrategy {
    private let rollThreshold: Double = 0.3
    private let maxRoll: Double = 0.9          // 이 값에서 강도 1.0(각도 51.6도일 때 최대)
    private let puckerThreshold: Double = 0.3

    public init() {}

    public func interpret(anchor: ARFaceAnchor) -> [InputEvent] {
        var out: [InputEvent] = []

        let roll = Double(atan2(anchor.transform.columns.1.x,
                                anchor.transform.columns.0.x))

        if abs(roll) > rollThreshold {
            let normalized = clamp(roll / maxRoll, -1.0, 1.0)
            out.append(.horizontal(normalized))
        }

        if let pucker = anchor.blendShapes[.mouthPucker]?.doubleValue,
           pucker > puckerThreshold {
            out.append(.action(.primary, value: min(1.0, pucker)))
        }

        return out
    }

    private func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double {
        min(hi, max(lo, x))
    }
}
