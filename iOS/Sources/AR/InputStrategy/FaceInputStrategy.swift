//
//  FaceInputStrategy.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import ARKit

protocol FaceInputStrategy {
    func interpret(anchor: ARFaceAnchor) -> [CharacterCommand]
}
