//
//  WebSocketSessionManager.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import Observation
import os

@Observable
public final class WebSocketSessionManager: WebSocketSessionManaging {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "WebSocketSessionManager")
    private let service: WebSocketService
    private let serverURL: String
    
    private var isActive = false

    public private(set) var players: [WebSocketPlayer] = []
    public private(set) var isConnected = false
    public private(set) var mySessionId: String?
    
    // MARK: - Callbacks
    
    public var onPlayersUpdated: (([WebSocketPlayer]) -> Void)?
    public var onPlayerJoined: ((WebSocketPlayer) -> Void)?
    public var onPlayerLeft: ((UUID) -> Void)?
    public var onInviteReceived: ((UUID) -> Void)?
    public var onInviteAccepted: ((UUID) -> Void)?
    public var onInviteDeclined: ((UUID) -> Void)?
    public var onInviteCancelled: ((UUID) -> Void)?
    public var onInputReceived: ((UUID, Data) -> Void)?
    public var onConnectionStateChanged: ((Bool) -> Void)?
    public var onReadyStatusReceived: ((UUID) -> Void)?
    public var onVideoReceived: ((UUID, Data) -> Void)?

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

        logger.info("WebSocket 탐색 시작 - channelId: \(channelId)")
        service.connect(to: serverURL, channelId: channelId, nickname: nickname)
    }

    public func deactivate() {
        guard isActive else { return }
        isActive = false

        logger.info("WebSocket 탐색 종료")
        service.leaveChannel()
        service.disconnect()
        players = []
        mySessionId = nil
    }
    
    public func sendInvite(to targetId: UUID) {
        guard let sessionId = sessionId(forPlayerId: targetId) else { return }
        service.sendInvite(to: sessionId)
    }
    
    public func acceptInvite(from targetId: UUID) {
        guard let sessionId = sessionId(forPlayerId: targetId) else { return }
        service.acceptInvite(from: sessionId)
    }
    
    public func declineInvite(from targetId: UUID) {
        guard let sessionId = sessionId(forPlayerId: targetId) else { return }
        service.declineInvite(from: sessionId)
    }
    
    public func cancelInvite(to targetId: UUID) {
        guard let sessionId = sessionId(forPlayerId: targetId) else { return }
        service.cancelInvite(to: sessionId)
    }
    
    public func sendInput<T: Codable>(_ data: T, to targetId: UUID?) {
        guard let targetId,
              let sessionId = sessionId(forPlayerId: targetId) else { return }

        service.sendInput(data, to: sessionId)
    }

    public func sendReadyStatus(to targetId: UUID) {
        guard let sessionId = sessionId(forPlayerId: targetId) else { return }
        service.sendReadyStatus(to: sessionId)
    }

    public func sendVideo(_ data: Data, to targetId: UUID?) {
        guard let targetId,
              let sessionId = sessionId(forPlayerId: targetId) else { return }

        service.sendVideo(data, to: sessionId)
    }

    public func getLatency(for playerId: UUID) -> Double? {
        return players.first { $0.id == playerId }?.latency
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
        case .ping:
            service.sendPong()
            
        case .pong:
            break
            
        case .channelPlayerList:
            handlePlayerList(message.payload)
            
        case .playerJoined:
            if let payload = message.payload {
                handlePlayerJoined(payload)
            }
            
        case .playerLeft:
            handlePlayerLeft(message.senderId)
            
        case .invite:
            onInviteReceived?(playerId(forSenderId: message.senderId))
            
        case .inviteAccept:
            onInviteAccepted?(playerId(forSenderId: message.senderId))
            
        case .inviteDecline:
            onInviteDeclined?(playerId(forSenderId: message.senderId))
            
        case .inviteCancel:
            onInviteCancelled?(playerId(forSenderId: message.senderId))
            
        case .input:
            if let payloadString = message.payload,
               let payloadData = payloadString.data(using: .utf8) {

                onInputReceived?(playerId(forSenderId: message.senderId), payloadData)
            }

        case .videoFrame:
            if let payloadString = message.payload {
                if let payloadData = Data(base64Encoded: payloadString) {
                    onVideoReceived?(playerId(forSenderId: message.senderId), payloadData)
                }
            }

        case .gameReady:
            onReadyStatusReceived?(playerId(forSenderId: message.senderId))

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
            guard parts.count >= 2 else { continue }

            let sessionId = String(parts[0])
            let nickname = String(parts[1])
            let latency = parts.count > 2 ? Double(parts[2]) : nil

            if sessionId == mySessionId { continue }

            let playerId = playerId(forSenderId: sessionId)
            newPlayers.append(WebSocketPlayer(id: playerId, sessionId: sessionId, nickname: nickname, latency: latency))
        }

        players = newPlayers
        onPlayersUpdated?(players)
    }
    
    private func handlePlayerJoined(_ payload: String) {
        let parts = payload.split(separator: ":")
        guard parts.count >= 2 else { return }

        let sessionId = String(parts[0])
        let nickname = String(parts[1])
        let latency = parts.count > 2 ? Double(parts[2]) : nil

        let playerId = playerId(forSenderId: sessionId)
        guard !players.contains(where: { $0.sessionId == sessionId }) else {
            return
        }

        let player = WebSocketPlayer(id: playerId, sessionId: sessionId, nickname: nickname, latency: latency)
        players.append(player)
        onPlayerJoined?(player)
    }
    
    private func handlePlayerLeft(_ senderId: String) {
        let playerId = playerId(forSenderId: senderId)
        players.removeAll { $0.sessionId == senderId || $0.nickname == senderId }
        onPlayerLeft?(playerId)
    }
}


// TODO: players 목록 동기화 전 메시지 수신 처리 개선 (임시 UUID fallback 제거)
extension WebSocketSessionManager {
    private func playerId(forSenderId senderId: String) -> UUID {
        if let cached = players.first(where: { $0.sessionId == senderId })?.id {
            return cached
        }
        return DeterministicUUID.fromString(senderId, namespace: "ws-sender")
    }

    private func sessionId(forPlayerId playerId: UUID) -> String? {
        players.first(where: { $0.id == playerId })?.sessionId
    }
}
