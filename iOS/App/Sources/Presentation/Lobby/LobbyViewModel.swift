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

    private(set) var myExplorer: LobbyExplorer
    private(set) var peers: [LobbyExplorer]
    var selectedPeerID: UUID?
    var userName: String
    var showPermissionAlert: Bool = false

    @ObservationIgnored
    private let sessionManager = NetworkSessionManager()

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

    init() {
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
        setupSessionManager()
    }
    
    // MARK: - Actions

    private func setupSessionManager() {
        sessionManager.onLocalNetworkPermissionDenied = { [weak self] in
            Task { @MainActor in
                self?.showPermissionAlert = true
                self?.sessionManager.deactive()
            }
        }
        
        // 탐색된 피어 업데이트 로직 (필요 시 추가)
        // sessionManager.onPeersUpdated = { ... }
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
    
    func selectPeer(id: UUID) {
        guard peers.contains(where: { $0.id == id }) else { return }
        selectedPeerID = id
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func startNetworkExploration() {
        sessionManager.activate(nickname: userName)
    }
    
    func stopNetworkExploration() {
        sessionManager.deactive()
    }
}
