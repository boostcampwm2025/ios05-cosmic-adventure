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
    public var onStatusChanged: ((Bool) -> Void)?

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    /// NWPathMonitor의 첫 번째 콜백 수신 여부. 초기 상태(false→false 등)에서도
    /// 콜백을 반드시 한 번 emit하기 위해 사용한다.
    /// 이 플래그 없이는 오프라인 상태에서 wasConnected == nowConnected이므로
    /// onStatusChanged가 호출되지 않아 LobbyViewModel.isConnectivityResolved가
    /// 영원히 false로 남는 버그가 발생한다.
    private var didEmitInitialStatus = false
    /// start()의 중복 호출을 방지하기 위한 플래그.
    private var isStarted = false

    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "NetworkKit.ConnectivityMonitor")
    }
    
    deinit {
        stop()
    }

    public func start() {
        // 여러 곳에서 start()가 호출되어도 NWPathMonitor는 한 번만 시작되도록 보장.
        guard !isStarted else { return }
        isStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self else { return }
                let wasConnected = self.isConnected
                let nowConnected = path.status == .satisfied

                self.isConnected = nowConnected
                self.connectionType = self.detectConnectionType(path)

                // 첫 번째 콜백은 상태 변경 여부와 관계없이 무조건 emit한다.
                // 이후에는 상태가 실제로 변경된 경우에만 emit한다.
                if !self.didEmitInitialStatus || wasConnected != nowConnected {
                    self.didEmitInitialStatus = true
                    self.onStatusChanged?(nowConnected)
                }
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
