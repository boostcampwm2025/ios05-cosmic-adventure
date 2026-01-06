//
//  FaceInputStrategy.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import ARKit

public protocol FaceInputStrategy {
    func interpret(anchor: ARFaceAnchor) -> [InputEvent]
}
