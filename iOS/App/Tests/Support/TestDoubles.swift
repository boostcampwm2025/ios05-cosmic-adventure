import Foundation
import Games
import NetworkKit
@testable import App

struct MockGameConfig: GameConfigProviding {
    let jumpSensitivity: SettingsLevel = .medium
    let tiltSensitivity: SettingsLevel = .medium
    let facePreviewSize: SettingsLevel = .medium
}

final class MockConnectionSessionManager: ConnectionSessionManaging {
    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    func activate(channelId: String?, nickname: String) {}
    func deactivate() {}
    func sendInvite(to targetId: UUID) {}
    func acceptInvite(from targetId: UUID) {}
    func declineInvite(from targetId: UUID) {}
    func cancelInvite(to targetId: UUID) {}
    func sendInput<T: Codable>(_ data: T, to targetId: UUID?) {}
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
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
