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

    // Network State
    var isConnected = false
    private(set) var networkMode: NetworkMode = .local
    var selectedChannelId: String?

    // Match State
    var matchStatus: GameMatchStatus = .idle

    @ObservationIgnored
    let explorationCoordinator: NetworkExplorationCoordinator

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring

    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?

    @ObservationIgnored
    let appEntryManager: AppEntryManager

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
        explorationCoordinator: NetworkExplorationCoordinator,
        connectivityMonitor: ConnectivityMonitoring,
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging?,
        appEntryManager: AppEntryManager,
        playerId: UUID,
        nickname: String,
        characterRawValue: String
    ) {
        self.explorationCoordinator = explorationCoordinator
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.appEntryManager = appEntryManager
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
        setupExploration()
        setupNotificationHandlers()
        resetToIdle()
    }

    private func setupNotificationHandlers() {
        NotificationManager.shared.onAcceptInvite = { [weak self] in
            self?.acceptInvite()
        }
        NotificationManager.shared.onDeclineInvite = { [weak self] in
            self?.declineInvite()
        }
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
            networkMode = .remote
        } else {
            networkMode = .local
            selectedChannelId = nil
        }
        setupExploration()
    }
}

// MARK: - Network Mode & Exploration

extension LobbyViewModel {
    func switchNetworkMode(to mode: NetworkMode) {
        networkMode = mode
        if mode == .remote {
            selectedChannelId = nil
        }
        setupExploration()
    }

    func setupExploration() {
        switch networkMode {
        case .local:
            Task {
                let isPermissionGranted = await appEntryManager.isLocalNetworkPermissionGranted()
                if !isPermissionGranted {
                    appEntryManager.presentAlert(.localNetworkDenied)
                    matchStatus.reset()
                    return
                }
                
                setupSessionManager()
                explorationCoordinator.updateExploration(
                    mode: .local,
                    channelId: nil,
                    nickname: localPlayer.displayName
                )
            }
        case .remote:
            guard let channelId = selectedChannelId else { return }
            explorationCoordinator.updateExploration(
                mode: .remote,
                channelId: channelId,
                nickname: localPlayer.displayName
            )
        }
    }
}

// MARK: - Channel Management

extension LobbyViewModel {
    func selectChannel(_ channelId: String) {
        networkMode = .remote
        selectedChannelId = channelId
        setupExploration()
    }

    func leaveChannel() {
        explorationCoordinator.stopExploration()
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
    func setSoloMode() {
        matchStatus.setSoloGame()
    }

    func resetToIdle() {
        matchStatus.reset()
        selectedPeerID = nil
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
            matchStatus.receiveInvite(from: peer, wasSoloGame: false)
        case .soloGame:
            // TODO: - 알림 권한 사전 확인 필요, 권한이 없다면 초대를 수신받을 수 없음
            NotificationManager.shared.sendInviteNotification(from: peer)
            matchStatus.receiveInvite(from: peer, wasSoloGame: true)
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
            if case .receivedInvite(_, let wasSoloGame) = matchStatus {
                if wasSoloGame {
                    setSoloMode()
                } else {
                    resetToIdle()
                }
            }
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
        guard case .receivedInvite(let peer, _) = matchStatus else { return }

        switch networkMode {
        case .local:
            networkSessionManager.acceptInvite(from: peer.id)

        case .remote:
            webSocketSessionManager?.acceptInvite(from: peer.id)
        }

        matchStatus.setGameReady(with: peer)
    }

    func declineInvite() {
        guard case .receivedInvite(let peer, let wasSoloGame) = matchStatus else { return }

        switch networkMode {
        case .local:
            networkSessionManager.declineInvite(from: peer.id)

        case .remote:
            webSocketSessionManager?.declineInvite(from: peer.id)
        }

        if wasSoloGame {
            setSoloMode()
        } else {
            resetToIdle()
        }
    }

    func confirmDecline() {
        resetToIdle()
    }
}
