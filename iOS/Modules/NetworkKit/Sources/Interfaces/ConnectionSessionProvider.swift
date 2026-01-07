//
//  ConnectionSessionProvider.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation

public protocol ConnectionSessionProvider {
    var nearbyPlayer: [Peer] { get }

    var onLocalNetworkPermissionGranted: (() -> Void)? { get set }
    var onLocalNetworkPermissionDenied: ((Error) -> Void)? { get set }

    func activate(nickname: String)
    func deactive()
}
