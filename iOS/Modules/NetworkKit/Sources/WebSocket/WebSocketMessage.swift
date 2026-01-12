//
//  WebSocketMessage.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public struct WebSocketMessage: Codable {
    public let type: String
    public let senderId: String
    public let payload: String?
    public let timestamp: Date?

    public init(type: WebSocketMessageType, senderId: String, payload: String? = nil) {
        self.type = type.rawValue
        self.senderId = senderId
        self.payload = payload
        self.timestamp = Date()
    }

    public var messageType: WebSocketMessageType? {
        WebSocketMessageType(rawValue: type)
    }
}
