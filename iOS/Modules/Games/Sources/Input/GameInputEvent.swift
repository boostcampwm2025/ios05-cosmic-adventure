//
//  GameInputEvent.swift
//  Games
//
//  Created by 영빈 on 1/8/26.
//

import Foundation

public enum GameInputEvent: Sendable, Equatable {
    case horizontal(Double)
    case jump
}
