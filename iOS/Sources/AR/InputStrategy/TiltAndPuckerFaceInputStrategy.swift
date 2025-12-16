//
//  TiltAndPuckerFaceInputStrategy.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import ARKit

final class TiltAndPuckerFaceInputStrategy: FaceInputStrategy {

    private let rollThreshold: Float = 0.3
    private let puckerThreshold: Double = 0.3

    func interpret(anchor: ARFaceAnchor) -> [CharacterCommand] {
        var events: [CharacterCommand] = []

        if let horizontalEvent = horizontalMovementEvent(from: anchor) {
            events.append(horizontalEvent)
        }

        if let jumpEvent = jumpEvent(from: anchor) {
            events.append(jumpEvent)
        }

        return events
    }
    
    private func horizontalMovementEvent(from anchor: ARFaceAnchor) -> CharacterCommand? {
        let roll = atan2(
            anchor.transform.columns.1.x,
            anchor.transform.columns.0.x
        )

        if roll > rollThreshold {
            return .moveRight(Double(roll))
        }

        if roll < -rollThreshold {
            return .moveLeft(Double(-roll))
        }

        return nil
    }
    
    private func jumpEvent(from anchor: ARFaceAnchor) -> CharacterCommand? {
        guard let pucker = anchor.blendShapes[.mouthPucker]?.doubleValue,
              pucker > puckerThreshold else {
            return nil
        }

        return .jump(pucker)
    }
}

