//
//  ClientManaging.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Network

public protocol ClientManaging {
    var onPermissionGranted: (() -> Void)? { get set }
    var onPermissionDeniedOrFailed: ((Error) -> Void)? { get set }
    var onPeersUpdated: (([Peer]) -> Void)? { get set }
    var onDataReceived: ((Data, NWConnection) -> Void)? { get set }

    func startBrowsing()
    func stopBrowsing()
    func connectToHost(endpoint: NWEndpoint) async throws
    func sendData(_ data: Data)
}
