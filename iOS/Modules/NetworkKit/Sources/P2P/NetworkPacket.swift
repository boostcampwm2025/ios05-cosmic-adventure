//
//  NetworkPacket.swift
//  NetworkKit
//
//  Created by soyoung on 1/9/26.
//

import Foundation

public struct NetworkPacket: Codable {
    public let type: NetworkPacketType
    public let senderIdentifier: String
    public let payload: Data?
    public let channel: ConnectionKind?

    public init(
        type: NetworkPacketType,
        senderIdentifier: String,
        payload: Data? = nil,
        channel: ConnectionKind? = nil
    ) {
        self.type = type
        self.senderIdentifier = senderIdentifier
        self.payload = payload
        self.channel = channel
    }
}
