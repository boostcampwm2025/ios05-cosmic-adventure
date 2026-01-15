//
//  LobbyViewModel+WebSocket.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import NetworkKit

// MARK: - WebSocket

extension LobbyViewModel {

    func setupWebSocketCallbacks() {
        guard webSocketSessionManager != nil else { return }

        setupConnectionCallbacks()
        setupPlayerManagementCallbacks()
        setupInvitationCallbacks()
    }

    private func setupConnectionCallbacks() {
        webSocketSessionManager?.onConnectionStateChanged = { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
                if !connected {
                    self?.peers = []
                    self?.playerIdMapping = [:]
                    self?.selectedPeerID = nil
                    self?.matchStatus = .idle
                }
            }
        }
    }

    private func setupPlayerManagementCallbacks() {
        webSocketSessionManager?.onPlayersUpdated = { [weak self] players in
            Task { @MainActor in
                self?.updatePeersFromPlayers(players)
            }
        }

        webSocketSessionManager?.onPlayerJoined = { [weak self] player in
            Task { @MainActor in
                self?.addPeer(from: player)
            }
        }

        webSocketSessionManager?.onPlayerLeft = { [weak self] playerId in
            Task { @MainActor in
                self?.removePeer(playerId: playerId)
            }
        }
    }

    private func setupInvitationCallbacks() {
        webSocketSessionManager?.onInviteReceived = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteReceived(from: senderName)
            }
        }

        webSocketSessionManager?.onInviteAccepted = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteAccepted(from: senderName)
            }
        }

        webSocketSessionManager?.onInviteDeclined = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteDeclined(from: senderName)
            }
        }

        webSocketSessionManager?.onInviteCancelled = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteCancelled(from: senderName)
            }
        }
    }
}

// MARK: - Helper Methods (Player Management)

extension LobbyViewModel {

    func updatePeersFromPlayers(_ players: [WebSocketPlayer]) {
        playerIdMapping.removeAll()
        peers = players.map { player in
            playerIdMapping[player.id] = player.id
            let proximity = calculateProximity(latency: player.latency)
            return LobbyExplorer(
                id: player.id,
                role: .peer,
                displayName: player.nickname,
                avatar: randomAvatar(),
                proximity: proximity
            )
        }
    }

    func addPeer(from player: WebSocketPlayer) {
        guard playerIdMapping[player.id] == nil else { return }

        playerIdMapping[player.id] = player.id

        let proximity = calculateProximity(latency: player.latency)
        
        // Proximity 확인을 위한 print문으로 정상 동작이 확인되면 제거
        print("🌐 [LobbyViewModel+WebSocket] 플레이어 추가: \(player.nickname), latency: \(player.latency?.description ?? "nil")ms, proximity: \(proximity)")

        let explorer = LobbyExplorer(
            id: player.id,
            role: .peer,
            displayName: player.nickname,
            avatar: randomAvatar(),
            proximity: proximity
        )
        peers.append(explorer)
    }

    func removePeer(playerId: String) {
        guard let id = playerIdMapping[playerId] else { return }
        peers.removeAll { $0.id == id }
        playerIdMapping.removeValue(forKey: playerId)

        if selectedPeerID == id {
            selectedPeerID = nil
        }
    }

    func randomAvatar() -> CharacterAvatar {
        let avatars: [CharacterAvatar] = [.character1, .character2, .character3, .character4, .character5, .character6]
        return avatars.randomElement() ?? .character1
    }
}
