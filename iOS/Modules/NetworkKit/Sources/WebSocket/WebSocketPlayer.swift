//
//  WebSocketPlayer.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/16/26.
//

import Foundation

public struct WebSocketPlayer: Identifiable, Equatable {
    public let id: UUID
    public let sessionId: String
    public let nickname: String
    public var latency: Double?
    
    public init(id: UUID, sessionId: String, nickname: String, latency: Double? = nil) {
        self.id = id
        self.sessionId = sessionId
        self.nickname = nickname
        self.latency = latency
    }
}
