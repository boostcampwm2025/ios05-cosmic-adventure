//
//  ConnectivityMonitor.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import Network
import Observation

@Observable
public final class ConnectivityMonitor: ConnectivityMonitoring, @unchecked Sendable {

    public enum ConnectionType: Sendable {
        case wifi
        case cellular
        case unknown
    }

    public private(set) var isConnected: Bool = false
    public private(set) var connectionType: ConnectionType = .unknown

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue

    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "NetworkKit.ConnectivityMonitor")
    }

    public func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.detectConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    public func stop() {
        monitor.cancel()
    }

    private func detectConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else {
            return .unknown
        }
    }
}
