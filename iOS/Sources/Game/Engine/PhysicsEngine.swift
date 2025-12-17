//
//  PhysicsEngine.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import Foundation

protocol PhysicsEngine {
    func addCharacter(
        id: UUID,
        size: CGSize,
        position: CGPoint
    )

    func apply(_ command: CharacterCommand, to id: UUID)
    func characterState(id: UUID) -> CharacterState
}
