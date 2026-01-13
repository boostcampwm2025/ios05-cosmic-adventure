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

    // MARK: - Data

    case input
}
