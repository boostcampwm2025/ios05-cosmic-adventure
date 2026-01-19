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
    private var isActive = false

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
    public var onInputReceived: ((String, Data) -> Void)?
    public var onConnectionStateChanged: ((Bool) -> Void)?
    public var onReadyStatusReceived: ((String) -> Void)?

    // MARK: - Initialization
    
    public init(service: WebSocketService, serverURL: String) {
        self.service = service
        self.serverURL = serverURL

        setupCallbacks()
    }
    
    // MARK: - Public Methods
    
    public func activate(channelId: String?, nickname: String) {
        guard !isActive else { return }
        guard let channelId = channelId else { return }
        isActive = true

        service.connect(to: serverURL, channelId: channelId, nickname: nickname)
    }

    public func deactivate() {
        guard isActive else { return }
        isActive = false

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
    
    public func sendInput<T: Codable>(_ data: T, to playerId: String?) {
        guard let playerId = playerId else { return }

        guard let jsonData = try? JSONEncoder().encode(data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        service.sendInput(jsonString, to: playerId)
    }

    public func sendReadyStatus(to playerId: String) {
        service.sendReadyStatus(to: playerId)
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
            if let payloadString = message.payload,
               let payloadData = payloadString.data(using: .utf8) {

                onInputReceived?(message.senderId, payloadData)
            }

        case .gameReady:
            onReadyStatusReceived?(message.senderId)

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
