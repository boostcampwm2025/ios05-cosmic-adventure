//
//  NetworkPacketHeader.swift
//  NetworkKit
//
//  Created by soyoung on 1/9/26.
//

public struct NetworkPacketHeader: Codable {
    public let type: NetworkPacketType
    public let senderName: String
}
