//
//  CharacterState.swift
//  Games
//
//  Created by soyoung on 1/7/26.
//

import Foundation

public struct CharacterState: Equatable {
    public var moveX: Double = 0 // 좌우 이동 속도 비율 (-1.0 ~ 1.0)
    public var jumpCount: Int = 0
    public var isGrounded: Bool = false
}
