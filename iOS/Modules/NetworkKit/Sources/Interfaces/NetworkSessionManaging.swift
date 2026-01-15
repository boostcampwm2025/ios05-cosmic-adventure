//
//  NetworkSessionManaging.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation

public enum LocalNetworkError: Error {
    case denied
    case unknown
}

public protocol NetworkSessionManaging: ConnectionSessionManaging {
    var nearbyPlayer: [Peer] { get }
    var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)? { get set }
    var onPeersUpdated: (([Peer]) -> Void)? { get set }
}
