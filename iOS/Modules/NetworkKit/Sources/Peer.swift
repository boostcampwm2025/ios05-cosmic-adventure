//
//  Peer.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Network

public enum PeerStatus: String {
    case available
    case busy
}

public struct Peer: Identifiable, Equatable {
    public var id: String { endpoint.debugDescription }
    public let name: String
    public let status: PeerStatus
    public let endpoint: NWEndpoint
}
