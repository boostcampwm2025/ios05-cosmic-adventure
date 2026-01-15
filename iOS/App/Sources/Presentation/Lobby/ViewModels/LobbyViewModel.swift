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
    var selectedPeerID: UUID?

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
    var playerIdMapping: [String: UUID] = [:]
    
    @ObservationIgnored
    private var isExplorationStarted = false

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

        // TODO: 네트워크 탐색 결과 보여주면서 제거 예정
        self.peers = [
            LobbyExplorer(role: .peer, displayName: "건방진 탐험가 1", avatar: .character1, proximity: 0.72),
            LobbyExplorer(role: .peer, displayName: "호기심천국", avatar: .character2, proximity: 0.95),
            LobbyExplorer(role: .peer, displayName: "자고있는 사람1", avatar: .character4, proximity: 0.28),
            LobbyExplorer(role: .peer, displayName: "행복한 탐험가1", avatar: .character5, proximity: 0.55),
            LobbyExplorer(role: .peer, displayName: "우주방랑자", avatar: .character6, proximity: 0.10)
        ]
        self.selectedPeerID = nil
        
        setupConnectivityMonitor()

        setupP2PCallbacks()
        setupWebSocketCallbacks()
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
    
    // TODO: proximity 업데이트 빈도/스케줄 정의 (실시간/주기적/디바운스 필요?)
    // TODO: proximity 변경에 따른 재정렬 애니메이션 정책 (너무 자주 움직이면 UX 저하)
    func updateProximity(for explorerID: UUID, value: Double) {
        guard let index = peers.firstIndex(where: { $0.id == explorerID }) else { return }
        peers[index].proximity = max(0, min(1, value))
    }
    
    func startSoloAdventure() {
        // TODO: GameView로 네비게이션 연결
    }
    
    func switchToLocalMode() {
        networkMode = .local
        stopNetworkExploration()
        startNetworkExploration()
    }
    
    func switchToRemoteMode() {
        networkMode = .remote
        selectedChannelId = nil
        stopNetworkExploration()
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
        guard !isExplorationStarted else { return }
        isExplorationStarted = true
        
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
        isExplorationStarted = false
        
        switch networkMode {
        case .local:
            networkSessionManager.deactivate()
        case .remote:
            webSocketSessionManager?.deactivate()
        }
    }

    func resetToIdle() {
        matchStatus.reset()
        selectedPeerID = nil
    }
}


// MARK: - Invite Event Handlers
extension LobbyViewModel {
    func handleInviteReceived(from senderName: String) {
        guard let peer = peers.first(where: { $0.displayName == senderName }) else { return }

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
