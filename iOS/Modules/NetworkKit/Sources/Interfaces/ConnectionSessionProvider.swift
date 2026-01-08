//
//  ConnectionSessionProvider.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation

public enum LocalNetworkError: Error {
    case denied
    case unknown
}

public protocol ConnectionSessionProvider {
    var nearbyPlayer: [Peer] { get }

    var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)? { get set }
    var onReceiveInvitationPacket: ((NetworkPacketType, Data) -> Void)? { get set }
//    var onReceiveGamePacket: ((Data, Data) -> Void)? { get set }

    func activate(nickname: String)
    func deactive()
    func requestInvite<T: NetworkTransferable>(to peer: Peer, packet: T)
    func replyToInvite<T: NetworkTransferable>(to targetName: String, packet: T)
}
