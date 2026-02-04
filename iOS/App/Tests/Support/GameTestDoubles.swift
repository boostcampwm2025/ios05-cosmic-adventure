//
//  GameTestDoubles.swift
//  App
//
//  Created by 영빈 on 2/5/26.
//

import Foundation
import Games
import NetworkKit
@testable import App

struct MockGameConfig: GameConfigProviding {
    let jumpSensitivity: SettingsLevel = .medium
    let tiltSensitivity: SettingsLevel = .medium
    let facePreviewSize: SettingsLevel = .medium
}

final class MockMultiplayerIO: MultiplayerNetworkManaging {
    var boundPeerId: UUID?
    var notifiedReasons: [GameEndReason] = []
    var onGameEndReceivedHandler: (@Sendable (NetworkGameEndDTO) -> Void)?
    var didTick: [TimeInterval] = []

    func bind(peerId: UUID) {
        boundPeerId = peerId
    }

    func unbind() {}

    func notifyGameEnded(_ reason: GameEndReason) {
        notifiedReasons.append(reason)
    }

    func setOnGameEndReceived(_ handler: @escaping @Sendable (NetworkGameEndDTO) -> Void) {
        onGameEndReceivedHandler = handler
    }

    func tick(deltaTime: TimeInterval) {
        didTick.append(deltaTime)
    }
}
