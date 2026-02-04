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

/// 로비 화면의 세 가지 상태.
/// networkMode와 selectedChannelId 두 프로퍼티의 조합을 하나의 enum으로 통합하여,
/// 상태 전환 시 cleanup 누락(human error)을 구조적으로 방지한다.
enum LobbyScreenState: Equatable {
    /// P2P 근거리 탐색 모드
    case local
    /// 원격 모드, 채널 미선택 (로고 + 채널 리스트 화면, 매치메이킹 불가)
    case channelList
    /// 원격 모드, 채널 선택됨
    case channel(id: String)
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
    var selectedPlayerID: UUID?

    // Network State
    var isConnected = false
    private(set) var screenState: LobbyScreenState = .local {
        didSet {
            guard oldValue != screenState else { return }
            handleScreenTransition(from: oldValue, to: screenState)
        }
    }
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

    var networkMode: NetworkMode {
        switch screenState {
        case .local: return .local
        case .channelList, .channel: return .remote
        }
    }

    var isOnChannelList: Bool {
        screenState == .channelList
    }

    var isNetwork: Bool {
        if case .channel = screenState { return true }
        return false
    }

    var selectedChannelId: String? {
        if case .channel(let id) = screenState { return id }
        return nil
    }

    /// 현재 활성 네트워크 연결. 채널 리스트에서는 nil (매치메이킹 불가).
    private var activeConnection: ConnectionSessionManaging? {
        switch screenState {
        case .local: return networkSessionManager
        case .channel: return webSocketSessionManager
        case .channelList: return nil
        }
    }

    var orderedPlayers: [PlayerInfo] {
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
        self.selectedPlayerID = nil
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

    func playLobbyBGM() {
        AudioManager.shared.playBGM(.lobby)
    }

    func stopLobbyBGM() {
        AudioManager.shared.stopBGM()
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
        self.isConnected = isConnected
        isConnectivityResolved = true
        if isConnected {
            if case .channel = screenState {
                // 이미 채널에 접속 중이면 유지
            } else {
                screenState = .channelList
            }
        } else {
            screenState = .local
        }
    }
}

// MARK: - Network Mode & Exploration

extension LobbyViewModel {
    func switchNetworkMode(to mode: NetworkMode) {
        switch mode {
        case .local:  screenState = .local
        case .remote: screenState = .channelList
        }
    }

    func setupExploration() {
        permissionCheckTask?.cancel()
        switch screenState {
        case .local:
            setupLocalExploration()
        case .channel(let id):
            explorationCoordinator.updateExploration(
                mode: .remote,
                channelId: id,
                nickname: localPlayer.displayName,
                characterRawValue: player.character
            )
        case .channelList:
            explorationCoordinator.stopExploration()
        }
    }

    private func handleScreenTransition(from oldState: LobbyScreenState, to newState: LobbyScreenState) {
        // Exit Actions
        switch oldState {
        case .channel, .local:
            remotePlayers = []
        default:
            break
        }

        // Enter Actions
        if newState == .channelList {
            cleanupMatchState()
        }

        setupExploration()
    }

    private func setupLocalExploration() {
        permissionCheckTask?.cancel()
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
                nickname: localPlayer.displayName,
                characterRawValue: player.character
            )
        }
    }

    // TODO: 채널 리스트 전환 시 매치 취소 확인 UI 추가
    private func cleanupMatchState() {
        switch matchStatus {
        case .sendingRequest(let player):
            if networkSessionManager.nearbyPlayer.contains(where: { $0.sessionId == player.id }) {
                networkSessionManager.cancelInvite(to: player.id)
            }
            if webSocketSessionManager?.players.contains(where: { $0.id == player.id }) == true {
                webSocketSessionManager?.cancelInvite(to: player.id)
            }

        case .receivedInvite(let player, _):
            if networkSessionManager.nearbyPlayer.contains(where: { $0.sessionId == player.id }) {
                networkSessionManager.declineInvite(from: player.id)
            }
            if webSocketSessionManager?.players.contains(where: { $0.id == player.id }) == true {
                webSocketSessionManager?.declineInvite(from: player.id)
            }

        default:
            break
        }

        matchStatus.reset()
        inviteNotifications.removeAll()
        isShowingNotification = false
        selectedPlayerID = nil
    }
}

// MARK: - Channel Management

extension LobbyViewModel {
    func selectChannel(_ channelId: String) {
        screenState = .channel(id: channelId)
    }

    func leaveChannel() {
        screenState = .channelList
    }
}

// MARK: - Player Management

extension LobbyViewModel {
    func selectPlayer(_ player: PlayerInfo) {
        self.selectedPlayerID = player.id
        self.matchStatus.select(player)
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
        selectedPlayerID = nil
    }
}

// MARK: - Invite Event Handlers

extension LobbyViewModel {
    func handleInviteReceived(from senderId: UUID) {
        guard !isOnChannelList else { return }
        guard let player = remotePlayers.first(where: { $0.id == senderId }) else {
            logger.warning("초대한 플레이어를 찾을 수 없음: \(senderId.uuidString)")
            return
        }
        self.isShowingNotification = false

        if !inviteNotifications.contains(where: { $0.sender.id == senderId }) {
            inviteNotifications.insert(InviteNotification(sender: player), at: 0)
        }

        switch matchStatus {
        case .idle:
            matchStatus.receiveInvite(from: player, wasSoloGame: false)
        case .soloGame:
            // TODO: - 알림 권한 사전 확인 필요, 권한이 없다면 초대를 수신받을 수 없음
            NotificationManager.shared.sendInviteNotification(from: player)
            matchStatus.receiveInvite(from: player, wasSoloGame: true)
        default:
            break
        }
    }

    func handleInviteAccepted(from senderId: UUID) {
        guard !isOnChannelList else { return }
        guard let player = remotePlayers.first(where: { $0.id == senderId }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.setGameReady(with: player)
        }
    }

    func handleInviteDeclined(from senderId: UUID) {
        guard !isOnChannelList else { return }
        guard let player = remotePlayers.first(where: { $0.id == senderId }) else { return }

        if case .sendingRequest = matchStatus {
            matchStatus.requestDeclined(by: player)
        }
    }

    func handleInviteCancelled(from senderId: UUID) {
        guard !isOnChannelList else { return }
        inviteNotifications.removeAll { $0.sender.id == senderId }

        if case .receivedInvite(let player, let wasSoloGame) = matchStatus, player.id == senderId {
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
        guard case .readyToSend(let player) = matchStatus else { return }
        matchStatus.sendRequest()
        activeConnection?.sendInvite(to: player.id)
    }

    func cancelInvite() {
        if case .sendingRequest(let player) = matchStatus {
            activeConnection?.cancelInvite(to: player.id)
        }
        resetToIdle()
    }

    func acceptInvite() {
        guard case .receivedInvite(let player, _) = matchStatus else { return }
        activeConnection?.acceptInvite(from: player.id)
        matchStatus.setGameReady(with: player)
    }

    func declineInvite() {
        guard case .receivedInvite(let player, let wasSoloGame) = matchStatus else { return }
        activeConnection?.declineInvite(from: player.id)
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
        guard !isOnChannelList else { return }
        let wasSoloGame = matchStatus == .soloGame
        matchStatus = .receivedInvite(player: notification.sender, wasSoloGame: wasSoloGame)
        acceptInvite()
        inviteNotifications.removeAll { $0.id == notification.id }
        isShowingNotification = false
    }
    
    func declineInviteFromNotification(_ notification: InviteNotification) {
        guard !isOnChannelList else { return }
        let wasSoloGame = matchStatus == .soloGame
        matchStatus = .receivedInvite(player: notification.sender, wasSoloGame: wasSoloGame)
        declineInvite()
        inviteNotifications.removeAll { $0.id == notification.id }
    }
}
