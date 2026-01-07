//
//  GameInputProviding.swift
//  Games
//
//  Created by 영빈 on 1/8/26.
//

import Foundation

public protocol GameInputProviding: AnyObject, Sendable {
    func start()
    func stop()
    func events() async -> AsyncStream<GameInputEvent>
}
