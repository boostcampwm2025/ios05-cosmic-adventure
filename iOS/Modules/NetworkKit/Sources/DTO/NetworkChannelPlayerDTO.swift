//
//  NetworkChannelPlayerDTO.swift
//  NetworkKit
//
//  Created by 영빈 on 2/4/26.
//

import Foundation

/// WebSocket 채널 플레이어 목록 / 입장 메시지에 사용되는 Wire DTO.
/// 백엔드와 iOS 간 JSON 인코딩/디코딩에 사용된다.
public struct NetworkChannelPlayerDTO: Codable {
    public let sessionId: String
    public let nickname: String
    public let characterRawValue: String
    public let latency: Double?

    public init(sessionId: String, nickname: String, characterRawValue: String, latency: Double?) {
        self.sessionId = sessionId
        self.nickname = nickname
        self.characterRawValue = characterRawValue
        self.latency = latency
    }
}

/// 수신자의 sessionId를 포함하는 channelPlayerList 응답 래퍼.
public struct NetworkChannelPlayerListDTO: Codable {
    public let youSessionId: String
    public let players: [NetworkChannelPlayerDTO]

    public init(youSessionId: String, players: [NetworkChannelPlayerDTO]) {
        self.youSessionId = youSessionId
        self.players = players
    }
}
