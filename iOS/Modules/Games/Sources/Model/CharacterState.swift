//
//  CharacterState.swift
//  Games
//
//  Created by soyoung on 1/7/26.
//

import Foundation

public struct CharacterPosition: Sendable, Codable, Equatable {
    public var x: Double
    public var y: Double
    public static let zero = CharacterPosition(x: 0, y: 0)

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct CharacterState: Equatable, Sendable {
    public var moveX: Double = 0 // 좌우 이동 속도 비율 (-1.0 ~ 1.0)
    public var position: CharacterPosition = .zero
    public var hasNetworkPosition: Bool = false
    public var jumpCount: Int = 0
    public var isGrounded: Bool = false
    public var respawn: RespawnState

    public init(
        moveX: Double = 0,
        position: CharacterPosition = .zero,
        hasNetworkPosition: Bool = false,
        jumpCount: Int = 0,
        isGrounded: Bool = true
    ) {
        self.moveX = moveX
        self.position = position
        self.hasNetworkPosition = hasNetworkPosition
        self.jumpCount = jumpCount
        self.isGrounded = isGrounded
        self.respawn = RespawnState()
    }
}
