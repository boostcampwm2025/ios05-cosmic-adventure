//
//  PhysicsCategory.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

struct PhysicsCategory: OptionSet {
    let rawValue: UInt32

    static let player = PhysicsCategory(rawValue: 1 << 0)
    static let ground = PhysicsCategory(rawValue: 1 << 1)
    static let monster = PhysicsCategory(rawValue: 1 << 2)
    static let wall  = PhysicsCategory(rawValue: 1 << 3)

    // 플레이어가 물리적으로 부딪혀야 하는 대상 (땅, 벽)
    static let playerCollidesWith: PhysicsCategory = [.ground, .wall]

    // 플레이어가 닿았을 때 감지해야 하는 대상 (땅, 괴물)
    static let playerContactsWith: PhysicsCategory = [.ground, .monster]
}
