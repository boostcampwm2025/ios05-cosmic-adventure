//
//  ConnectivityMonitoring.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public protocol ConnectivityMonitoring: AnyObject, Sendable {
    var isConnected: Bool { get }
    var connectionType: ConnectivityMonitor.ConnectionType { get }
    var onStatusChanged: ((Bool) -> Void)? { get set }
    
    func start()
    func stop()
}
