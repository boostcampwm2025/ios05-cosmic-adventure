//
//  NetworkTransferable.swift
//  NetworkKit
//
//  Created by soyoung on 1/9/26.
//

public protocol NetworkTransferable: Codable {
    var type: NetworkPacketType { get }
    var senderIdentifier: String { get }
}
