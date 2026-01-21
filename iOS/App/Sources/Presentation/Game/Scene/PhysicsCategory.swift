//
//  PhysicsCategory.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

struct PhysicsCategory: OptionSet {
    let rawValue: UInt32

    static let playerMe = PhysicsCategory(rawValue: 1 << 0)
    static let playerOther = PhysicsCategory(rawValue: 1 << 1)

    static let groundMe = PhysicsCategory(rawValue: 1 << 2)
    static let groundOther = PhysicsCategory(rawValue: 1 << 3)

    static let monster = PhysicsCategory(rawValue: 1 << 4)
    static let wall  = PhysicsCategory(rawValue: 1 << 5)

    static let anyPlayer: PhysicsCategory = PhysicsCategory(rawValue: PhysicsCategory.playerMe.rawValue | PhysicsCategory.playerOther.rawValue)
    static let anyGround: PhysicsCategory = PhysicsCategory(rawValue: PhysicsCategory.groundMe.rawValue | PhysicsCategory.groundOther.rawValue)
}
