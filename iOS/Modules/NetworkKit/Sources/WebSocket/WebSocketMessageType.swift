//
//  WebSocketMessageType.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

public enum WebSocketMessageType: String, Codable {
    
    // MARK: - Channel
    
    case channelJoin
    case channelLeave
    case channelPlayerList
    case playerJoined
    case playerLeft
    
    // MARK: - Invitation
    
    case invite
    case inviteAccept
    case inviteDecline
    case inviteCancel

    // MARK: - Status

    case gameReady

    // MARK: - Data
    
    case input
    
    // MARK: - Connection
    
    case ping
    case pong
}
