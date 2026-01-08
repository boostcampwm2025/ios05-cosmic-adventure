//
//  GamePacket.swift
//  NetworkKit
//
//  Created by soyoung on 1/8/26.
//

import Foundation

// 메시지 종류
public enum GameMessageType: String, Codable {
    case invite
    case accept
    case decline
    case cancelInvite
}

// 메세지 전송 패킷
public struct GamePacket: Codable {
    public let type: GameMessageType
    public let senderNickname: String
    public let payload: String? // 추가정보

    public init(type: GameMessageType, senderNickname: String, payload: String? = nil) {
        self.type = type
        self.senderNickname = senderNickname
        self.payload = payload
    }
}
