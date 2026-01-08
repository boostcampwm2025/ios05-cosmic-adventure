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

    func activate(nickname: String)
    func deactive()
}
