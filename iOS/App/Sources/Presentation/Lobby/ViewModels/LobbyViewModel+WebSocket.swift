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
                    self?.remotePlayers = []
                    self?.selectedPeerID = nil
                    self?.matchStatus = .idle
                }
            }
        }
    }

    private func setupPlayerManagementCallbacks() {
        webSocketSessionManager?.onPlayersUpdated = { [weak self] players in
            guard let self = self else { return }

            let activePlayerIds = Set(players.map { $0.id })

            Task { @MainActor in
                self.updatePeersFromPlayers(players)
                self.inviteNotifications.removeAll { !activePlayerIds.contains($0.sender.id) }
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
        webSocketSessionManager?.onInviteReceived = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteReceived(from: senderId)
            }
        }

        webSocketSessionManager?.onInviteAccepted = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteAccepted(from: senderId)
            }
        }

        webSocketSessionManager?.onInviteDeclined = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteDeclined(from: senderId)
            }
        }

        webSocketSessionManager?.onInviteCancelled = { [weak self] senderId in
            Task { @MainActor in
                self?.handleInviteCancelled(from: senderId)
            }
        }
    }
}

// MARK: - Helper Methods (Player Management)

extension LobbyViewModel {

    func updatePeersFromPlayers(_ players: [WebSocketPlayer]) {
        remotePlayers = players.map { player in
            let proximity = calculateProximity(latency: player.latency)
            return PlayerInfo(
                id: player.id,
                role: .remote,
                displayName: player.nickname,
                avatar: randomAvatar(),
                proximity: proximity
            )
        }
    }

    func addPeer(from player: WebSocketPlayer) {
        guard remotePlayers.contains(where: { $0.id == player.id }) == false else { return }

        let proximity = calculateProximity(latency: player.latency)

        let player = PlayerInfo(
            id: player.id,
            role: .remote,
            displayName: player.nickname,
            avatar: randomAvatar(),
            proximity: proximity
        )
        remotePlayers.append(player)
    }

    func removePeer(playerId: UUID) {
        remotePlayers.removeAll { $0.id == playerId }

        if selectedPeerID == playerId {
            selectedPeerID = nil
        }
    }

    func randomAvatar() -> CharacterAvatar {
        let avatars: [CharacterAvatar] = [.character1, .character2, .character3, .character4, .character5, .character6]
        return avatars.randomElement() ?? .character1
    }
}
