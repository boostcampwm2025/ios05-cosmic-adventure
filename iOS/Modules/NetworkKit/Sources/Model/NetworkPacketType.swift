//
//  NetworkPacketType.swift
//  NetworkKit
//
//  Created by soyoung on 1/8/26.
//

// 메시지 종류
public enum NetworkPacketType: String, Codable {
    case invite
    case accept
    case decline
    case cancelInvite
//    case gameData
}
