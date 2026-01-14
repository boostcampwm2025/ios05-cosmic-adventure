//
//  PlayerRuntime.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/14/26.
//

import Foundation

struct PlayerRuntime: Sendable {
    var lastJumpTime: TimeInterval = 0
    var lastLandingTime: TimeInterval = 0
    var timeSinceLastInput: TimeInterval = 0
}
