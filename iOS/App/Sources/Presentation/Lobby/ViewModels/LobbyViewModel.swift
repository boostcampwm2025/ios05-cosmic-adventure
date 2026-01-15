//
//  LobbyViewModel.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import Observation
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

    private(set) var myExplorer: LobbyExplorer
    var peers: [LobbyExplorer]
    var selectedPeerID: String?

    var activeAlert: LobbyAlert = .none
    var showPermissionAlert: Bool {
        get { activeAlert != .none }
        set { if !newValue { activeAlert = .none } }
    }
    
    var isConnected = false
    
    private(set) var networkMode: NetworkMode = .local
    
    var selectedChannelId: String?

    var matchStatus: GameMatchStatus = .idle

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring
    
    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging
    
    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?
    
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
        
        self.myExplorer = LobbyExplorer(
            role: .me,
            displayName: nickname,
            avatar: CharacterAvatar(rawValue: characterRawValue) ?? .character1
        )

        self.selectedPeerID = nil
        
        self.setupConnectivityMonitor()
        self.setupP2PCallbacks()
        self.setupWebSocketCallbacks()
    }
    
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
    }
    
    // MARK: - Common Actions
    
    // TODO: proximity 업데이트 빈도/스케줄 정의 (실시간/주기적/디바운스 필요)
    // TODO: proximity 변경에 따른 재정렬 애니메이션 정책 (너무 자주 움직이면 UX 저하)
    func updateProximity(for explorerID: String, value: Double) {
        guard let index = peers.firstIndex(where: { $0.id == explorerID }) else { return }
        peers[index].proximity = max(0, min(1, value))
    }
    
    // MARK: - Proximity Calculation
    
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
    
    func startSoloAdventure() {
        // TODO: GameView로 네비게이션 연결
    }
    
    func switchToLocalMode() {
        networkMode = .local
    }

    func switchToRemoteMode() {
        networkMode = .remote
        selectedChannelId = nil
    }
    
    func selectPeer(_ peer: LobbyExplorer) {
        self.selectedPeerID = peer.id
        self.matchStatus.select(peer)
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func startNetworkExploration() {
        switch networkMode {
        case .local:
            setupSessionManager()
            networkSessionManager.activate(nickname: myExplorer.displayName)
        case .remote:
            guard let channelId = selectedChannelId else { return }
            webSocketSessionManager?.activate(channelId: channelId, nickname: myExplorer.displayName)
        }
    }

    func stopNetworkExploration() {
        networkSessionManager.deactivate()
        webSocketSessionManager?.deactivate()
    }

    func resetToIdle() {
        matchStatus.reset()
        selectedPeerID = nil
    }
}


// MARK: - Invite Event Handlers

extension LobbyViewModel {
    func handleInviteReceived(from senderName: String) {
        guard let peer = peers.first(where: { $0.displayName == senderName }) else {
            print("❌ [LobbyViewModel] 초대한 피어를 찾을 수 없음: \(senderName). 현재 피어들: \(peers.map { $0.displayName })")
            return
        }

        switch matchStatus {
        case .idle:
            matchStatus.receiveInvite(from: peer)
        default:
            break
        }
    }

    func handleInviteAccepted(from senderName: String) {
        guard let peer = peers.first(where: { $0.displayName == senderName }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.setGameReady(with: peer)
        }
    }

    func handleInviteDeclined(from senderName: String) {
        guard let peer = peers.first(where: { $0.displayName == senderName }) else { return }

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
