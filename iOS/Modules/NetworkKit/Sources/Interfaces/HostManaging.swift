//
//  HostManaging.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Network

public protocol HostManaging {
    var onPermissionGranted: (() -> Void)? { get set }
    var onPermissionDeniedOrFailed: ((Error) -> Void)? { get set }
    var onDataReceived: ((Data, NWConnection) -> Void)? { get set }

    func startHosting(nickName: String, status: PeerStatus, sessionId: UUID)
    func stopHosting()
    func sendData(_ data: Data, to connection: NWConnection)
    func sendData(_ data: Data, to connection: NWConnection, completion: @escaping (NWError?) -> Void)
}
