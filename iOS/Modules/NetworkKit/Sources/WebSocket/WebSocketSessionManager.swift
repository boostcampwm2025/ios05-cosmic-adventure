//
//  WebSocketSessionManager.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import Observation

public struct WebSocketPlayer: Identifiable, Equatable {
    public let id: String
    public let nickname: String
    
    public init(id: String, nickname: String) {
        self.id = id
        self.nickname = nickname
    }
}

@Observable
public final class WebSocketSessionManager: WebSocketSessionManaging {
    
    // MARK: - Properties
    
    private let service: WebSocketService
    private let serverURL: String
    private let channelId: String
    
    public private(set) var players: [WebSocketPlayer] = []
    public private(set) var isConnected = false
    public private(set) var mySessionId: String?
    
    // MARK: - Callbacks
    
    public var onPlayersUpdated: (([WebSocketPlayer]) -> Void)?
    public var onPlayerJoined: ((WebSocketPlayer) -> Void)?
    public var onPlayerLeft: ((String) -> Void)?
    public var onInviteReceived: ((String) -> Void)?
    public var onInviteAccepted: ((String) -> Void)?
    public var onInviteDeclined: ((String) -> Void)?
    public var onInviteCancelled: ((String) -> Void)?
    public var onInputReceived: ((String, String) -> Void)?
    public var onConnectionStateChanged: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    public init(service: WebSocketService = .shared, serverURL: String, channelId: String) {
        self.service = service
        self.serverURL = serverURL
        self.channelId = channelId
        
        setupCallbacks()
    }
    
    // MARK: - Public Methods
    
    public func activate(nickname: String) {
        service.connect(to: serverURL, channelId: channelId, nickname: nickname)
    }
    
    public func deactivate() {
        service.leaveChannel()
        service.disconnect()
        players = []
        mySessionId = nil
    }
    
    public func sendInvite(to playerId: String) {
        service.sendInvite(to: playerId)
    }
    
    public func acceptInvite(from playerId: String) {
        service.acceptInvite(from: playerId)
    }
    
    public func declineInvite(from playerId: String) {
        service.declineInvite(from: playerId)
    }
    
    public func cancelInvite(to playerId: String) {
        service.cancelInvite(to: playerId)
    }
    
    public func sendInput(_ data: String, to playerId: String) {
        service.sendInput(data, to: playerId)
    }
    
    // MARK: - Private Methods
    
    private func setupCallbacks() {
        service.onConnect = { [weak self] in
            self?.handleConnect()
        }
        
        service.onDisconnect = { [weak self] _ in
            self?.handleDisconnect()
        }
        
        service.onMessage = { [weak self] message in
            self?.handleMessage(message)
        }
    }
    
    private func handleConnect() {
        isConnected = true
        service.joinChannel()
        onConnectionStateChanged?(true)
    }
    
    private func handleDisconnect() {
        isConnected = false
        players = []
        mySessionId = nil
        onConnectionStateChanged?(false)
    }
    
    private func handleMessage(_ message: WebSocketMessage) {
        switch message.messageType {
        case .channelPlayerList:
            handlePlayerList(message.payload)
            
        case .playerJoined:
            if let payload = message.payload {
                handlePlayerJoined(payload)
            }
            
        case .playerLeft:
            handlePlayerLeft(message.senderId)
            
        case .invite:
            onInviteReceived?(message.senderId)
            
        case .inviteAccept:
            onInviteAccepted?(message.senderId)
            
        case .inviteDecline:
            onInviteDeclined?(message.senderId)
            
        case .inviteCancel:
            onInviteCancelled?(message.senderId)
            
        case .input:
            if let payload = message.payload {
                onInputReceived?(message.senderId, payload)
            }
            
        default:
            break
        }
    }
    
    private func handlePlayerList(_ payload: String?) {
        guard let payload else { return }
        
        mySessionId = service.sessionId
        var newPlayers: [WebSocketPlayer] = []
        
        let playerStrings = payload.split(separator: "|")
        for playerString in playerStrings {
            let parts = playerString.split(separator: ":")
            guard parts.count == 2 else { continue }
            
            let sessionId = String(parts[0])
            let nickname = String(parts[1])
            
            if sessionId == mySessionId { continue }
            
            newPlayers.append(WebSocketPlayer(id: sessionId, nickname: nickname))
        }
        
        players = newPlayers
        onPlayersUpdated?(players)
    }
    
    private func handlePlayerJoined(_ payload: String) {
        let parts = payload.split(separator: ":")
        guard parts.count == 2 else { return }
        
        let sessionId = String(parts[0])
        let nickname = String(parts[1])
        
        guard !players.contains(where: { $0.id == sessionId }) else { return }
        
        let player = WebSocketPlayer(id: sessionId, nickname: nickname)
        players.append(player)
        onPlayerJoined?(player)
    }
    
    private func handlePlayerLeft(_ sessionId: String) {
        players.removeAll { $0.id == sessionId }
        onPlayerLeft?(sessionId)
    }
}
