//
//  GameReadyTestDoubles.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 2/5/26.
//

import Foundation
import NetworkKit
@testable import App

@MainActor
struct GameReadyMockPermissionService: PermissionServicing {
    func refreshCameraState() -> PermissionState { .allowed }
    func requestCameraIfNeeded() async -> Bool { true }
    func requestLocalNetworkPermissionIfNeeded() async -> Bool { true }
    func requestNotificationPermission() async -> Bool { true }
    func openAppSettings() {}
}

final class GameReadyMockConnectivityMonitor: ConnectivityMonitoring, @unchecked Sendable {
    var isConnected: Bool
    var connectionType: ConnectivityMonitor.ConnectionType = .wifi
    var onStatusChanged: ((Bool) -> Void)?

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    func start() {
        onStatusChanged?(isConnected)
    }

    func stop() {}
}

final class GameReadyMockNetworkSessionManager: NetworkSessionManaging {
    struct SentInput {
        let targetId: UUID?
        let payload: Data
    }

    var nearbyPlayer: [NetworkPeer] = []
    var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)?
    var onPeersUpdated: (([NetworkPeer]) -> Void)?

    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    private(set) var sentInputs: [SentInput] = []

    func activate(channelId: String?, nickname: String, characterRawValue: String) {}
    func deactivate() {}
    func sendInvite(to targetId: UUID) {}
    func acceptInvite(from targetId: UUID) {}
    func declineInvite(from targetId: UUID) {}
    func cancelInvite(to targetId: UUID) {}
    func sendGameData<T: Codable>(_ data: T, to targetId: UUID?) {
        if let payload = try? JSONEncoder().encode(data) {
            sentInputs.append(SentInput(targetId: targetId, payload: payload))
        }
    }
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
}

final class GameReadyMockWebSocketSessionManager: WebSocketSessionManaging {
    struct SentInput {
        let targetId: UUID?
        let payload: Data
    }

    var players: [WebSocketPlayer] = []
    var isConnected: Bool = true
    var mySessionId: String?

    var onPlayersUpdated: (([WebSocketPlayer]) -> Void)?
    var onPlayerJoined: ((WebSocketPlayer) -> Void)?
    var onPlayerLeft: ((UUID) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?

    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    private(set) var sentInputs: [SentInput] = []

    func activate(channelId: String?, nickname: String, characterRawValue: String) {}
    func deactivate() {}
    func sendInvite(to targetId: UUID) {}
    func acceptInvite(from targetId: UUID) {}
    func declineInvite(from targetId: UUID) {}
    func cancelInvite(to targetId: UUID) {}
    func sendGameData<T: Codable>(_ data: T, to targetId: UUID?) {
        if let payload = try? JSONEncoder().encode(data) {
            sentInputs.append(SentInput(targetId: targetId, payload: payload))
        }
    }
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
}
