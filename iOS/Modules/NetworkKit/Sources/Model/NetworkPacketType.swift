//
//  NetworkPacketType.swift
//  NetworkKit
//
//  Created by soyoung on 1/8/26.
//

public enum NetworkPacketType: String, Codable {
    case invite
    case accept
    case decline
    case cancelInvite
}
