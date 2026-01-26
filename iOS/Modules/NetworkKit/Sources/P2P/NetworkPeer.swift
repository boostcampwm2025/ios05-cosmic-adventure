//
//  NetworkPeer.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Network

public enum PeerStatus: String {
    case available
    case busy
}

public struct NetworkPeer: Identifiable, Equatable {
    public var id: String { endpoint.debugDescription }
    public let sessionId: UUID
    public let name: String
    public let status: PeerStatus
    public let endpoint: NWEndpoint
    public var latency: Double?
}
