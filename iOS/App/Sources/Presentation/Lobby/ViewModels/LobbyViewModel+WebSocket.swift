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
        guard let webSocketSessionManager else { return }
        
        webSocketSessionManager.onConnectionStateChanged = { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
                if !connected {
                    self?.peers = []
                    self?.playerIdMapping = [:]
                }
            }
        }
        
        webSocketSessionManager.onPlayersUpdated = { [weak self] players in
            Task { @MainActor in
                self?.updatePeersFromPlayers(players)
            }
        }
        
        webSocketSessionManager.onPlayerJoined = { [weak self] player in
            Task { @MainActor in
                self?.addPeer(from: player)
            }
        }
        
        webSocketSessionManager.onPlayerLeft = { [weak self] playerId in
            Task { @MainActor in
                self?.removePeer(playerId: playerId)
            }
        }
    }
    
    func updatePeersFromPlayers(_ players: [WebSocketPlayer]) {
        playerIdMapping.removeAll()
        peers = players.map { player in
            let uuid = UUID()
            playerIdMapping[player.id] = uuid
            return LobbyExplorer(
                id: uuid,
                role: .peer,
                displayName: player.nickname,
                avatar: randomAvatar(),
                proximity: Double.random(in: 0.1...0.9)
            )
        }
    }
    
    func addPeer(from player: WebSocketPlayer) {
        guard playerIdMapping[player.id] == nil else { return }
        
        let uuid = UUID()
        playerIdMapping[player.id] = uuid
        
        let explorer = LobbyExplorer(
            id: uuid,
            role: .peer,
            displayName: player.nickname,
            avatar: randomAvatar(),
            proximity: Double.random(in: 0.1...0.9)
        )
        peers.append(explorer)
    }
    
    func removePeer(playerId: String) {
        guard let uuid = playerIdMapping[playerId] else { return }
        peers.removeAll { $0.id == uuid }
        playerIdMapping.removeValue(forKey: playerId)
        
        if selectedPeerID == uuid {
            selectedPeerID = nil
        }
    }
    
    func randomAvatar() -> CharacterAvatar {
        let avatars: [CharacterAvatar] = [.character1, .character2, .character3, .character4, .character5, .character6]
        return avatars.randomElement() ?? .character1
    }
}

// MARK: - Invite Actions

extension LobbyViewModel {

    func sendInvite(to peerId: UUID) {
        guard networkMode == .remote,
              let playerId = playerIdMapping.first(where: { $0.value == peerId })?.key else { return }
        webSocketSessionManager?.sendInvite(to: playerId)
    }
    
    func acceptInvite(from playerId: String) {
        guard networkMode == .remote else { return }
        webSocketSessionManager?.acceptInvite(from: playerId)
    }
    
    func declineInvite(from playerId: String) {
        guard networkMode == .remote else { return }
        webSocketSessionManager?.declineInvite(from: playerId)
    }
    
    func cancelInvite(to peerId: UUID) {
        guard networkMode == .remote,
              let playerId = playerIdMapping.first(where: { $0.value == peerId })?.key else { return }
        webSocketSessionManager?.cancelInvite(to: playerId)
    }
}
