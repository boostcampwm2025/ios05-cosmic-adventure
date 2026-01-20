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

    // Explorer
    private(set) var myExplorer: LobbyExplorer
    var peers: [LobbyExplorer] = []
    var selectedPeerID: String?

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

    // Internal State
    @ObservationIgnored
    var playerIdMapping: [String: String] = [:]

    // MARK: - Computed Properties

    var isNetworkAvailable: Bool {
        connectivityMonitor.isConnected
    }

    var orderedPeers: [LobbyExplorer] {
        peers.sorted { lhs, rhs in
            switch (lhs.proximity, rhs.proximity) {
            case let (l?, r?): return l > r
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
        nickname: String,
        characterRawValue: String
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.selectedPeerID = nil
        
        self.myExplorer = LobbyExplorer(
            role: .me,
            displayName: nickname,
            avatar: CharacterAvatar(rawValue: characterRawValue) ?? .character1
        )

        self.selectedPeerID = nil

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
        switch networkMode {
        case .local:
            setupSessionManager()
            networkSessionManager.activate(nickname: myExplorer.displayName)
        case .remote:
            guard let channelId = selectedChannelId else {
                logger.warning("Remote 모드지만 selectedChannelId가 nil")
                return
            }
            webSocketSessionManager?.activate(channelId: channelId, nickname: myExplorer.displayName)
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

// MARK: - Peer Management

extension LobbyViewModel {
    func selectPeer(_ peer: LobbyExplorer) {
        self.selectedPeerID = peer.id
        self.matchStatus.select(peer)
    }

    func updateProximity(for explorerID: String, value: Double) {
        guard let index = peers.firstIndex(where: { $0.id == explorerID }) else { return }
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

        return 1.0 - ((clamped - minLat) / (maxLat - minLat))
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
// TODO: - UUID 추가 후 id와 name 모두 확인하는 로직으로 수정
extension LobbyViewModel {
    func handleInviteReceived(from senderIdentifier: String) {
        guard let peer = peers.first(where: { $0.id == senderIdentifier || $0.displayName == senderIdentifier }) else {
            logger.warning("초대한 피어를 찾을 수 없음: \(senderIdentifier)")
            return
        }

        switch matchStatus {
        case .idle:
            matchStatus.receiveInvite(from: peer)
        default:
            break
        }
    }

    func handleInviteAccepted(from senderIdentifier: String) {
        guard let peer = peers.first(where: { $0.id == senderIdentifier || $0.displayName == senderIdentifier }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.setGameReady(with: peer)
        }
    }

    func handleInviteDeclined(from senderIdentifier: String) {
        guard let peer = peers.first(where: { $0.id == senderIdentifier || $0.displayName == senderIdentifier }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.requestDeclined(by: peer)
        }
    }

    func handleInviteCancelled(from senderName: String) {
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
            networkSessionManager.sendInvite(to: peer.displayName)

        case .remote:
            if let playerId = playerIdMapping.first(where: { $0.value == peer.id })?.key {
                webSocketSessionManager?.sendInvite(to: playerId)
            }
        }
    }

    func cancelInvite() {
        if case .sendingRequest(let peer) = matchStatus {
            switch networkMode {
            case .local:
                networkSessionManager.cancelInvite(to: peer.displayName)

            case .remote:
                if let playerId = playerIdMapping.first(where: { $0.value == peer.id })?.key {
                    webSocketSessionManager?.cancelInvite(to: playerId)
                }
            }
        }

        resetToIdle()
    }

    func acceptInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        switch networkMode {
        case .local:
            networkSessionManager.acceptInvite(from: peer.displayName)

        case .remote:
            if let playerId = playerIdMapping.first(where: { $0.value == peer.id })?.key {
                webSocketSessionManager?.acceptInvite(from: playerId)
            }
        }

        matchStatus.setGameReady(with: peer)
    }

    func declineInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        switch networkMode {
        case .local:
            networkSessionManager.declineInvite(from: peer.displayName)

        case .remote:
            if let playerId = playerIdMapping.first(where: { $0.value == peer.id })?.key {
                webSocketSessionManager?.declineInvite(from: playerId)
            }
        }

        resetToIdle()
    }

    func confirmDecline() {
        resetToIdle()
    }
}
