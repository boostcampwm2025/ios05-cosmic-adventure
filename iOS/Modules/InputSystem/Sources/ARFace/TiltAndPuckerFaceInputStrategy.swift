//
//  TiltAndPuckerFaceInputStrategy.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import ARKit

final class TiltAndPuckerFaceInputStrategy: FaceInputStrategy {
    
    // MARK: - Properties
    
    private let rollThreshold: Double
    private let maxRoll: Double
    private let puckerThreshold: Double
    private let jawOpenThreshold = InputConstants.Face.jawOpenThreshold

    // MARK: - Initialization
    
    init(
        puckerThreshold: Double = InputConstants.Face.defaultPuckerThreshold,
        rollThreshold: Double = InputConstants.Face.rollThreshold,
        maxRoll: Double = InputConstants.Face.maxRoll
    ) {
        self.puckerThreshold = puckerThreshold
        self.rollThreshold = rollThreshold
        self.maxRoll = maxRoll
    }
    
    // MARK: - Methods

    func interpret(anchor: ARFaceAnchor) -> [InputEvent] {
        var out: [InputEvent] = []

        let roll = Double(atan2(anchor.transform.columns.1.x,
                                anchor.transform.columns.0.x))

        if abs(roll) > rollThreshold {
            let normalized = clamp(roll / maxRoll, -1.0, 1.0)
            out.append(.horizontal(normalized))
        } else {
            out.append(.horizontal(0))
        }

        let pucker = anchor.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        let jawOpen = anchor.blendShapes[.jawOpen]?.doubleValue ?? 0.0

        if pucker > puckerThreshold && jawOpen < jawOpenThreshold {
            out.append(.action(.jump, value: min(1.0, pucker)))
        }

        return out
    }

    private func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double {
        min(hi, max(lo, x))
    }
}
