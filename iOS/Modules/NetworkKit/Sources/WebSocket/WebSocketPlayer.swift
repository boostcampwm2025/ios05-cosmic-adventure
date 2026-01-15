//
//  WebSocketPlayer.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/16/26.
//

public struct WebSocketPlayer: Identifiable, Equatable {
    public let id: String
    public let nickname: String
    public var latency: Double?
    
    public init(id: String, nickname: String, latency: Double? = nil) {
        self.id = id
        self.nickname = nickname
        self.latency = latency
    }
}