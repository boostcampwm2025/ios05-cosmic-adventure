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

@MainActor
@Observable
final class LobbyViewModel {

    // MARK: - Properties

    private let decoder = JSONDecoder()
    private(set) var myExplorer: LobbyExplorer
    private(set) var peers: [LobbyExplorer]
    var selectedPeerID: UUID?
    var userName: String

    var activeAlert: LobbyAlert = .none
    var showPermissionAlert: Bool {
        get { activeAlert != .none }
        set { if !newValue { activeAlert = .none } }
    }

    var matchStatus: GameMatchStatus = .idle

    @ObservationIgnored
    private let sessionManager: NetworkSessionManager

    // MARK: - Computed Properties

    /// proximity 내림차순 정렬 (클수록 가까움 → 안쪽 궤도)
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

    //MARK: - Initialization

    init(sessionManager: NetworkSessionManager) {
        self.sessionManager = sessionManager

        self.userName = "건방진 탐험가 123"

        self.myExplorer = LobbyExplorer(
            role: .me,
            displayName: "나",
            avatar: .character3
        )

        self.peers = [
            LobbyExplorer(role: .peer, displayName: "건방진 탐험가 1", avatar: .character1, proximity: 0.72),
            LobbyExplorer(role: .peer, displayName: "호기심천국", avatar: .character2, proximity: 0.95),
            LobbyExplorer(role: .peer, displayName: "자고있는 사람1", avatar: .character4, proximity: 0.28),
            LobbyExplorer(role: .peer, displayName: "행복한 탐험가1", avatar: .character5, proximity: 0.55),
            LobbyExplorer(role: .peer, displayName: "우주방랑자", avatar: .character6, proximity: 0.10)
        ]

        self.selectedPeerID = nil
    }

    // MARK: - Actions

    private func setupSessionManager() {
        activeAlert = .none
        sessionManager.onPermissionResult = { [weak self] result in
            guard case .failure(let error) = result else { return }

            Task { @MainActor in
                self?.activeAlert = (error == .denied) ? .permissionDenied : .unknownNetworkError
            }
        }

        sessionManager.onReceiveInvitationPacket = { [weak self] type, data in
            self?.handleInvitationPacket(type: type, data: data)
        }
    }

    private func handleInvitationPacket(type: NetworkPacketType, data: Data) {
        // 보낸 사람(Peer) 찾기
        guard let packet = try? decoder.decode(InvitationPacket.self, from: data),
              let peer = peers.first(where: { $0.displayName == packet.senderIdentifier }) else {
            return }

        Task { @MainActor in
            switch type {
            case .invite:
                switch matchStatus {
                case .idle:
                    matchStatus = .receivedInvite(peer: peer)

                case .gameReady, .gameStart:
                    declineInGame(peer: peer)

                default:
                    break
                }

            case .accept:
                if case .sendingRequest = matchStatus {
                    matchStatus = .gameReady(peer: peer)
                }

            case .cancelInvite:
                if case .receivedInvite = matchStatus {
                    resetToIdle()
                }

            case .decline:
                if case .sendingRequest = matchStatus {
                    matchStatus = .requestDeclined(peer: peer)
                }
            }
        }
    }

    private func declineInGame(peer: LobbyExplorer) {
        let packet = InvitationPacket(type: .decline, senderIdentifier: userName)
        sessionManager.replyToInvite(to: peer.displayName, packet: packet)
    }

    private func resetToIdle() {
        matchStatus = .idle
        selectedPeerID = nil
    }

    // MARK: - Proximity Update (TODO)

    // TODO: proximity 업데이트 빈도/스케줄 정의 (실시간/주기적/디바운스 필요?)
    // TODO: proximity 변경에 따른 재정렬 애니메이션 정책 (너무 자주 움직이면 UX 저하)
    func updateProximity(for explorerID: UUID, value: Double) {
        guard let index = peers.firstIndex(where: { $0.id == explorerID }) else { return }
        peers[index].proximity = max(0, min(1, value))
    }

    // TODO: GameView로 네비게이션 연결

    func startSoloAdventure() {
        // Solo 모드 시작 로직
    }

    func selectPeer(_ peer: LobbyExplorer) {
        self.selectedPeerID = peer.id
        self.matchStatus = .readyToSend(peer: peer)
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func startNetworkExploration() {
        setupSessionManager()
        sessionManager.activate(nickname: userName)
    }

    func stopNetworkExploration() {
        sessionManager.deactive()
    }

    func sendInviteRequest() {
        guard case .readyToSend(let peer) = matchStatus else { return }
        matchStatus = .sendingRequest(peer: peer)

        let packet = InvitationPacket(type: .invite, senderIdentifier: userName)
        if let targetPeer = sessionManager.nearbyPlayer.first(where: { $0.name == peer.displayName }) {
            sessionManager.requestInvite(to: targetPeer, packet: packet)
        }
    }

    func cancelInviteRequest() {
        if case .sendingRequest(let peer) = matchStatus {
            let packet = InvitationPacket(type: .cancelInvite, senderIdentifier: userName)
            sessionManager.replyToInvite(to: peer.displayName, packet: packet)
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

        matchStatus = .gameReady(peer: peer)
    }

    func declineInvite() {
        guard case .receivedInvite(let peer) = matchStatus else { return }

        let packet = InvitationPacket(type: .decline, senderIdentifier: userName)
        sessionManager.replyToInvite(to: peer.displayName, packet: packet)

        resetToIdle()
    }
}
