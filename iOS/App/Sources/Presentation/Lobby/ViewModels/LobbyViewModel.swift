//
//  LobbyViewModel.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import Observation
import SwiftUI
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

    let decoder = JSONDecoder()
    private(set) var myExplorer: LobbyExplorer
    var peers: [LobbyExplorer]
    var selectedPeerID: UUID?
    var userName: String

    var activeAlert: LobbyAlert = .none
    var showPermissionAlert: Bool {
        get { activeAlert != .none }
        set { if !newValue { activeAlert = .none } }
    }
    
    var isConnected = false
    let networkMode: NetworkMode

    var matchStatus: GameMatchStatus = .idle

    @ObservationIgnored
    let sessionManager: NetworkSessionManager?
    
    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?
    
    @ObservationIgnored
    var playerIdMapping: [String: UUID] = [:]
    
    @ObservationIgnored
    private var isExplorationStarted = false

    // MARK: - Computed Properties

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
        sessionManager: NetworkSessionManager,
        webSocketSessionManager: WebSocketSessionManaging?,
        nickname: String
    ) {
        self.sessionManager = sessionManager
        self.webSocketSessionManager = webSocketSessionManager
        
        self.userName = "건방진 탐험가 123"

        self.myExplorer = LobbyExplorer(
            role: .me,
            displayName: "나",
            avatar: .character3
        )
        
        // TODO: P2P 연동 후 제거
        self.peers = [
            LobbyExplorer(role: .peer, displayName: "건방진 탐험가 1", avatar: .character1, proximity: 0.72),
            LobbyExplorer(role: .peer, displayName: "호기심천국", avatar: .character2, proximity: 0.95),
            LobbyExplorer(role: .peer, displayName: "자고있는 사람1", avatar: .character4, proximity: 0.28),
            LobbyExplorer(role: .peer, displayName: "행복한 탐험가1", avatar: .character5, proximity: 0.55),
            LobbyExplorer(role: .peer, displayName: "우주방랑자", avatar: .character6, proximity: 0.10)
        ]
        self.selectedPeerID = nil
    }
    
    init(webSocketSessionManager: WebSocketSessionManager, nickname: String) {
        self.networkMode = .remote
        self.sessionManager = nil
        self.webSocketSessionManager = webSocketSessionManager
        
        self.userName = nickname
        
        self.myExplorer = LobbyExplorer(
            role: .me,
            displayName: "나",
            avatar: .character3
        )
        
        self.peers = []
        self.selectedPeerID = nil
        
        setupWebSocketCallbacks()
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
            sessionManager?.activate(nickname: userName)
        case .remote:
            webSocketSessionManager?.activate(nickname: userName)
        }
    }

    func stopNetworkExploration() {
        isExplorationStarted = false
        
        switch networkMode {
        case .local:
            sessionManager?.deactive()
        case .remote:
            webSocketSessionManager?.deactivate()
        }
    }

    func sendInviteRequest() {
        guard case .readyToSend(let peer) = matchStatus else { return }
        matchStatus.sendRequest()

        let packet = InvitationPacket(type: .invite, senderIdentifier: userName)
        if let targetPeer = sessionManager?.nearbyPlayer.first(where: { $0.name == peer.displayName }) {
            sessionManager?.requestInvite(to: targetPeer, packet: packet)
        }
    }

    func cancelInviteRequest() {
        if case .sendingRequest(let peer) = matchStatus {
            let packet = InvitationPacket(type: .cancelInvite, senderIdentifier: userName)
            sessionManager?.replyToInvite(to: peer.displayName, packet: packet)
        }

        resetToIdle()
    }

    func confirmDecline() {
        resetToIdle()
    }

    func acceptInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        let packet = InvitationPacket(type: .accept, senderIdentifier: userName)
        sessionManager.replyToInvite(to: peer.displayName, packet: packet)

        matchStatus.setGameReady(with: peer)
    }

    func declineInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        let packet = InvitationPacket(type: .decline, senderIdentifier: userName)
        sessionManager.replyToInvite(to: peer.displayName, packet: packet)

        resetToIdle()
    }
}
