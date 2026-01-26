//
//  LobbyViewModel.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import Observation
import os
import UIKit
import NetworkKit

enum NetworkMode {
    case local
    case remote
}

@MainActor
@Observable
final class LobbyViewModel {

    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.cosmicadventure.app", category: "LobbyViewModel")

    // Player
    private(set) var localPlayer: PlayerInfo
    var peers: [PlayerInfo] = []
    var selectedPeerID: UUID?

    // UI State
    var activeAlert: LobbyAlert = .none
    var showPermissionAlert: Bool {
        get { activeAlert != .none }
        set { if !newValue { activeAlert = .none } }
    }

    // Network State
    var isConnected = false
    private(set) var networkMode: NetworkMode = .local
    var selectedChannelId: String?

    // Match State
    var matchStatus: GameMatchStatus = .idle

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring

    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?


    // MARK: - Computed Properties

    var isNetworkAvailable: Bool {
        connectivityMonitor.isConnected
    }

    var orderedPeers: [PlayerInfo] {
        peers.sorted { lhs, rhs in
            switch (lhs.proximity, rhs.proximity) {
            case let (l?, r?): return l < r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return false
            }
        }
    }

    // MARK: - Initialization

    init(
        connectivityMonitor: ConnectivityMonitoring,
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging?,
        playerId: UUID,
        nickname: String,
        characterRawValue: String
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.selectedPeerID = nil
        
        self.localPlayer = PlayerInfo(
            id: playerId,
            role: .me,
            displayName: nickname,
            avatar: CharacterAvatar(rawValue: characterRawValue) ?? .character1
        )
    }

    func setup() {
        setupConnectivityMonitor()
        setupP2PCallbacks()
        setupWebSocketCallbacks()
    }
}

// MARK: - Connectivity Management

extension LobbyViewModel {
    private func setupConnectivityMonitor() {
        connectivityMonitor.onStatusChanged = { [weak self] isConnected in
            Task { @MainActor in
                self?.handleConnectivityChange(isConnected: isConnected)
            }
        }
        connectivityMonitor.start()
        networkMode = connectivityMonitor.isConnected ? .remote : .local
    }

    private func handleConnectivityChange(isConnected: Bool) {
        if isConnected {
            stopNetworkExploration()
            networkMode = .remote
        } else {
            networkMode = .local
            selectedChannelId = nil
        }
    }
}

// MARK: - Network Mode & Exploration

extension LobbyViewModel {
    func switchToLocalMode() {
        stopNetworkExploration()
        networkMode = .local
    }

    func switchToRemoteMode() {
        stopNetworkExploration()
        networkMode = .remote
        selectedChannelId = nil
    }

    func startNetworkExploration() {
        resetToIdle()

        switch networkMode {
        case .local:
            setupSessionManager()
            networkSessionManager.activate(nickname: localPlayer.displayName)
        case .remote:
            guard let channelId = selectedChannelId else {
                logger.warning("Remote 모드지만 selectedChannelId가 nil")
                return
            }
            webSocketSessionManager?.activate(channelId: channelId, nickname: localPlayer.displayName)
        }
    }

    func stopNetworkExploration() {
        networkSessionManager.deactivate()
        webSocketSessionManager?.deactivate()
    }
}

// MARK: - Channel Management

extension LobbyViewModel {
    func selectChannel(_ channelId: String) {
        stopNetworkExploration()
        networkMode = .remote
        selectedChannelId = channelId
    }

    func leaveChannel() {
        stopNetworkExploration()
        selectedChannelId = nil
        peers = []
    }
}

// MARK: - NetworkPeer Management

extension LobbyViewModel {
    func selectPeer(_ peer: PlayerInfo) {
        self.selectedPeerID = peer.id
        self.matchStatus.select(peer)
    }

    func updateProximity(for playerID: UUID, value: Double) {
        guard let index = peers.firstIndex(where: { $0.id == playerID }) else { return }
        peers[index].proximity = max(0, min(1, value))
    }

    func calculateProximity(latency: Double?) -> Double {
        guard let latency else {
            return 0.5
        }

        let isLocal = networkMode == .local

        let minLat: Double = isLocal ? 1.0 : 20.0
        let maxLat: Double = isLocal ? 50.0 : 300.0

        let clamped = max(minLat, min(maxLat, latency))

        return (clamped - minLat) / (maxLat - minLat)
    }
}

// MARK: - Game Actions

extension LobbyViewModel {
    func resetToIdle() {
        matchStatus.reset()
        selectedPeerID = nil
    }
}

// MARK: - System

extension LobbyViewModel {
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Invite Event Handlers

extension LobbyViewModel {
    func handleInviteReceived(from senderId: UUID) {
        guard let peer = peers.first(where: { $0.id == senderId }) else {
            logger.warning("초대한 피어를 찾을 수 없음: \(senderId.uuidString)")
            return
        }
        
        switch matchStatus {
        case .idle:
            matchStatus.receiveInvite(from: peer)
        default:
            break
        }
    }

    func handleInviteAccepted(from senderId: UUID) {
        guard let peer = peers.first(where: { $0.id == senderId }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.setGameReady(with: peer)
        }
    }

    func handleInviteDeclined(from senderId: UUID) {
        guard let peer = peers.first(where: { $0.id == senderId }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.requestDeclined(by: peer)
        }
    }

    func handleInviteCancelled(from senderId: UUID) {
        if case .receivedInvite = matchStatus {
            resetToIdle()
        }
    }
}

// MARK: - Invite Actions

extension LobbyViewModel {
    func sendInvite() {
        guard case .readyToSend(let peer) = matchStatus else { return }
        matchStatus.sendRequest()

        switch networkMode {
        case .local:
            networkSessionManager.sendInvite(to: peer.id)

        case .remote:
            webSocketSessionManager?.sendInvite(to: peer.id)
        }
    }

    func cancelInvite() {
        if case .sendingRequest(let peer) = matchStatus {
            switch networkMode {
            case .local:
                networkSessionManager.cancelInvite(to: peer.id)

            case .remote:
                webSocketSessionManager?.cancelInvite(to: peer.id)
            }
        }

        resetToIdle()
    }

    func acceptInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        switch networkMode {
        case .local:
            networkSessionManager.acceptInvite(from: peer.id)

        case .remote:
            webSocketSessionManager?.acceptInvite(from: peer.id)
        }

        matchStatus.setGameReady(with: peer)
    }

    func declineInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        switch networkMode {
        case .local:
            networkSessionManager.declineInvite(from: peer.id)

        case .remote:
            webSocketSessionManager?.declineInvite(from: peer.id)
        }

        resetToIdle()
    }

    func confirmDecline() {
        resetToIdle()
    }
}
