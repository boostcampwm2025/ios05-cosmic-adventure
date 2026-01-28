//
//  LobbyViewModel+P2P.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import NetworkKit

// MARK: - P2P

extension LobbyViewModel {

    func setupSessionManager() {
        networkSessionManager.onPermissionResult = { [weak self] result in
            guard case .failure(let error) = result else { return }
            
            Task { @MainActor in
                guard error == .denied else { return }
                self?.appEntryManager.presentAlert(.localNetworkDenied)
                self?.matchStatus.reset()
                self?.explorationCoordinator.stopExploration()
            }
        }
    }

    func setupP2PCallbacks() {
        networkSessionManager.onPeersUpdated = { [weak self] peers in
            guard let self = self else { return }

            let activePeerIds = Set(peers.map { $0.sessionId })

            // 알림 리스트 중 접속 중이지 않은 유저의 알림 제거
            Task { @MainActor in
                self.updateLocalPeers(peers)
                self.inviteNotifications.removeAll { !activePeerIds.contains($0.sender.id) }
            }
        }

        networkSessionManager.onInviteReceived = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteReceived(from: senderId)
            }
        }

        networkSessionManager.onInviteAccepted = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteAccepted(from: senderId)
            }
        }

        networkSessionManager.onInviteDeclined = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteDeclined(from: senderId)
            }
        }

        networkSessionManager.onInviteCancelled = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteCancelled(from: senderId)
            }
        }
    }

    func updateLocalPeers(_ peers: [NetworkPeer]) {
        self.peers = peers.enumerated().map { index, peer in
            let discoveryLatency = Double(index * 10 + 5)
            let effectiveLatency = peer.latency ?? discoveryLatency
            let proximity = calculateProximity(latency: effectiveLatency)
            
            return PlayerInfo(
                id: peer.sessionId,
                role: .peer,
                displayName: peer.name,
                avatar: .character1,
                proximity: proximity
            )
        }
    }
}
