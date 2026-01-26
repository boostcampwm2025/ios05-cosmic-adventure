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
        activeAlert = .none
        networkSessionManager.onPermissionResult = { [weak self] result in
            guard case .failure(let error) = result else { return }
            
            Task { @MainActor in 
                self?.activeAlert = (error == .denied) ? .permissionDenied : .unknownNetworkError
            }
        }
    }

    func setupP2PCallbacks() {
        networkSessionManager.onPeersUpdated = { [weak self] peers in
            Task { @MainActor in
                self?.updateLocalPeers(peers)
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
