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

        networkSessionManager.onInviteReceived = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteReceived(from: senderName)
            }
        }

        networkSessionManager.onInviteAccepted = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteAccepted(from: senderName)
            }
        }

        networkSessionManager.onInviteDeclined = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteDeclined(from: senderName)
            }
        }

        networkSessionManager.onInviteCancelled = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteCancelled(from: senderName)
            }
        }
    }

    func updateLocalPeers(_ peers: [Peer]) {
        self.peers = peers.enumerated().map { index, peer in
            let id = peer.name
            playerIdMapping[peer.name] = id

            let discoveryLatency = Double(index * 10 + 5)
            let effectiveLatency = peer.latency ?? discoveryLatency
            let proximity = calculateProximity(latency: effectiveLatency)

            // Proximity 확인을 위한 print문으로 정상 동작이 확인되면 제거
            print("🚀 [LobbyViewModel] 피어 변환: \(peer.name), ID: \(id), Proximity: \(proximity)")

            return LobbyExplorer(
                id: id,
                role: .peer,
                displayName: peer.name,
                avatar: .character1,
                proximity: proximity
            )
        }
    }
}
