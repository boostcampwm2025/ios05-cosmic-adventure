//
//  LobbyViewModel.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import UIKit
import Observation
import os

import NetworkKit
import StorageKit

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
    private let player: Player
    var localPlayer: PlayerInfo {
        PlayerInfo(
            id: player.id,
            role: .local,
            displayName: player.nickname,
            avatar: CharacterAvatar(rawValue: player.character) ?? .character1)
    }

    var remotePlayers: [PlayerInfo] = []
    var selectedPeerID: UUID?

    // Network State
    var isConnected = false
    private(set) var networkMode: NetworkMode = .local
    var selectedChannelId: String?
    /// ConnectivityMonitor의 첫 번째 콜백이 오기 전까지 false.
    /// LobbyView에서 이 값이 true가 될 때까지 중립적 placeholder를 표시하여
    /// local↔remote 전환 시 발생하는 깜빡임을 방지한다.
    private(set) var isConnectivityResolved = false

    // Match State
    var matchStatus: GameMatchStatus = .idle

    // notification
    var inviteNotifications: [InviteNotification] = []
    var isShowingNotification: Bool = false

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

    /// setupExploration()에서 생성한 권한 체크 Task. 중복 호출 시 이전 Task를 cancel하기 위해 보관.
    @ObservationIgnored
    private var permissionCheckTask: Task<Void, Never>?
    
    @ObservationIgnored
    /// SwiftUI 라이프사이클 특성상 onAppear가 여러 번 호출될 수 있으므로,
    /// setup()의 중복 실행을 방지하기 위한 플래그.
    private var didSetup = false

    // MARK: - Computed Properties

    var isNetworkAvailable: Bool {
        connectivityMonitor.isConnected
    }

    var orderedPeers: [PlayerInfo] {
        remotePlayers.sorted { lhs, rhs in
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
        player: Player
    ) {
        self.explorationCoordinator = explorationCoordinator
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.appEntryManager = appEntryManager
        self.player = player
        self.selectedPeerID = nil
    }

    func setup() {
        // SwiftUI의 onAppear가 여러 번 호출되어도 setup은 한 번만 실행되도록 보장.
        guard !didSetup else { return }
        didSetup = true
        setupConnectivityMonitor()
        setupP2PCallbacks()
        setupWebSocketCallbacks()
        // setupExploration()은 여기서 직접 호출하지 않음.
        // ConnectivityMonitor의 첫 콜백(handleConnectivityChange)에서 호출되므로
        // networkMode가 확정된 후에만 탐색이 시작된다.
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
    }

    private func handleConnectivityChange(isConnected: Bool) {
        // ConnectivityMonitor 콜백에서 실제 네트워크 상태를 받아 확정.
        // isConnectivityResolved를 true로 설정하여 LobbyView가 placeholder 대신 실제 UI를 렌더링하도록 함.
        self.isConnected = isConnected
        isConnectivityResolved = true
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
        permissionCheckTask?.cancel()

        switch networkMode {
        case .local:
            permissionCheckTask = Task {
                let isPermissionGranted = await appEntryManager.isLocalNetworkPermissionGranted()
                guard !Task.isCancelled else { return }
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
        remotePlayers = []
    }
}

// MARK: - NetworkPeer Management

extension LobbyViewModel {
    func selectPeer(_ peer: PlayerInfo) {
        self.selectedPeerID = peer.id
        self.matchStatus.select(peer)
    }

    func updateProximity(for playerID: UUID, value: Double) {
        guard let index = remotePlayers.firstIndex(where: { $0.id == playerID }) else { return }
        remotePlayers[index].proximity = max(0, min(1, value))
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
        guard let peer = remotePlayers.first(where: { $0.id == senderId }) else {
            logger.warning("초대한 피어를 찾을 수 없음: \(senderId.uuidString)")
            return
        }
        self.isShowingNotification = false

        if !inviteNotifications.contains(where: { $0.sender.id == senderId }) {
            inviteNotifications.insert(InviteNotification(sender: peer), at: 0)
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
        guard let peer = remotePlayers.first(where: { $0.id == senderId }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.setGameReady(with: peer)
        }
    }

    func handleInviteDeclined(from senderId: UUID) {
        guard let peer = remotePlayers.first(where: { $0.id == senderId }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.requestDeclined(by: peer)
        }
    }

    func handleInviteCancelled(from senderId: UUID) {
        inviteNotifications.removeAll { $0.sender.id == senderId }

        if case .receivedInvite(let peer, let wasSoloGame) = matchStatus, peer.id == senderId {
            if wasSoloGame {
                setSoloMode()
            } else {
                resetToIdle()
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

// MARK: - notification Actions

extension LobbyViewModel {
    func acceptInviteFromNotification(_ notification: InviteNotification) {
        let wasSoloGame = matchStatus == .soloGame
        matchStatus = .receivedInvite(peer: notification.sender, wasSoloGame: wasSoloGame)
        acceptInvite()
        inviteNotifications.removeAll { $0.id == notification.id }
        isShowingNotification = false
    }
    
    func declineInviteFromNotification(_ notification: InviteNotification) {
        let wasSoloGame = matchStatus == .soloGame
        matchStatus = .receivedInvite(peer: notification.sender, wasSoloGame: wasSoloGame)
        declineInvite()
        inviteNotifications.removeAll { $0.id == notification.id }
    }
}
