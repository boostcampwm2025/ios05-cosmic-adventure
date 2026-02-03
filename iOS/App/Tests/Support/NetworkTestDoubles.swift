//
//  NetworkTestDoubles.swift
//  App
//
//  Created by 영빈 on 2/5/26.
//

import Foundation
import NetworkKit
@testable import App

final class MockConnectionSessionManager: ConnectionSessionManaging {
    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    func activate(channelId: String?, nickname: String, characterRawValue: String) {}
    func deactivate() {}
    func sendInvite(to targetId: UUID) {}
    func acceptInvite(from targetId: UUID) {}
    func declineInvite(from targetId: UUID) {}
    func cancelInvite(to targetId: UUID) {}
    func sendGameData<T: Codable>(_ data: T, to targetId: UUID?) {}
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
}

@MainActor
final class MockNetworkSessionManager: NetworkSessionManaging {
    var activateCalls: [(channelId: String?, nickname: String, characterRawValue: String)] = []
    var deactivateCallCount = 0
    var sendInviteCalls: [UUID] = []
    var cancelInviteCalls: [UUID] = []
    var acceptInviteCalls: [UUID] = []
    var declineInviteCalls: [UUID] = []

    // NetworkSessionManaging
    var nearbyPlayer: [NetworkPeer] = []
    var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)?
    var onPeersUpdated: (([NetworkPeer]) -> Void)?

    // ConnectionSessionManaging
    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    func activate(channelId: String?, nickname: String, characterRawValue: String) {
        activateCalls.append((channelId, nickname, characterRawValue))
    }

    func deactivate() { deactivateCallCount += 1 }
    func sendInvite(to targetId: UUID) { sendInviteCalls.append(targetId) }
    func acceptInvite(from targetId: UUID) { acceptInviteCalls.append(targetId) }
    func declineInvite(from targetId: UUID) { declineInviteCalls.append(targetId) }
    func cancelInvite(to targetId: UUID) { cancelInviteCalls.append(targetId) }
    func sendGameData<T: Codable>(_ data: T, to targetId: UUID?) {}
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
}

@MainActor
final class MockWebSocketSessionManager: WebSocketSessionManaging {
    var activateCalls: [(channelId: String?, nickname: String, characterRawValue: String)] = []
    var deactivateCallCount = 0
    var sendInviteCalls: [UUID] = []
    var cancelInviteCalls: [UUID] = []
    var acceptInviteCalls: [UUID] = []
    var declineInviteCalls: [UUID] = []

    // WebSocketSessionManaging
    var players: [WebSocketPlayer] = []
    var isConnected: Bool = false
    var mySessionId: String?
    var onPlayersUpdated: (([WebSocketPlayer]) -> Void)?
    var onPlayerJoined: ((WebSocketPlayer) -> Void)?
    var onPlayerLeft: ((UUID) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?

    // ConnectionSessionManaging
    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    func activate(channelId: String?, nickname: String, characterRawValue: String) {
        activateCalls.append((channelId, nickname, characterRawValue))
    }

    func deactivate() { deactivateCallCount += 1 }
    func sendInvite(to targetId: UUID) { sendInviteCalls.append(targetId) }
    func acceptInvite(from targetId: UUID) { acceptInviteCalls.append(targetId) }
    func declineInvite(from targetId: UUID) { declineInviteCalls.append(targetId) }
    func cancelInvite(to targetId: UUID) { cancelInviteCalls.append(targetId) }
    func sendGameData<T: Codable>(_ data: T, to targetId: UUID?) {}
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
}

final class MockConnectivityMonitor: ConnectivityMonitoring, @unchecked Sendable {
    var isConnected: Bool = false
    var connectionType: ConnectivityMonitor.ConnectionType = .wifi
    var onStatusChanged: ((Bool) -> Void)?

    func start() {}
    func stop() {}

    func simulateConnectivityChange(isConnected: Bool) {
        self.isConnected = isConnected
        onStatusChanged?(isConnected)
    }
}
