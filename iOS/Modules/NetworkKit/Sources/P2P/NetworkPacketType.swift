//
//  NetworkPacketType.swift
//  NetworkKit
//
//  Created by soyoung on 1/8/26.
//

public enum NetworkPacketType: String, Codable {
    // MARK: - Invitation

    case invite
    case inviteAccept
    case inviteDecline
    case inviteCancel

    // MARK: - Connection

    case ping
    case pong
    case channelHello

    // // MARK: - Status
    
    case gameReady

    // MARK: - Data

    case input
    case videoFrame
    case gameEnded
}
