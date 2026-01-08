//
//  NetworkTransferable.swift
//  NetworkKit
//
//  Created by soyoung on 1/9/26.
//

public protocol NetworkTransferable: Encodable {
    var type: NetworkPacketType { get }
    var senderName: String { get }
}
