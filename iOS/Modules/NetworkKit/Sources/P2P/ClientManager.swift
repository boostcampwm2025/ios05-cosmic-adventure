//
//  ClientManager.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Network
import os

final class ClientManager: ClientManaging {
    
    // MARK: - Properties
    
    private let serviceType = "_cosmicadventure._tcp"
    private let networkQueue = DispatchQueue(label: "com.cosmicadventure.client")

    private var browser: NWBrowser?
    private var connections: [NWEndpoint: NWConnection] = [:]

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "ClientManager")

    // MARK: - Callbacks

    var onPermissionGranted: (() -> Void)?
    var onPermissionDeniedOrFailed: ((Error) -> Void)?
    var onPeersUpdated: (([Peer]) -> Void)?
    var onDataReceived: ((Data, NWConnection) -> Void)?

    // MARK: - Initialization

    init() { }

    deinit {
        stopBrowsing()
        logger.info("ClientManager deinit")
    }

    // MARK: - Public Methods

    func startBrowsing() {
        logger.info("탐색 시작: \(self.serviceType)")

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: parameters)
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleBrowseResultsChanged(results: results, changes: changes)
        }

        browser?.stateUpdateHandler = { [weak self] state in
            self?.handleBrowserStateUpdate(state)
        }

        browser?.start(queue: networkQueue)
    }

    func stopBrowsing() {
        logger.info("탐색 종료")

        connections.forEach{ $0.value.cancel() }
        connections.removeAll()

        browser?.cancel()
        browser = nil
    }

    func connectToHost(endpoint: NWEndpoint) async throws {
        if let existingConnection = connections[endpoint] {
            switch existingConnection.state {
            case .ready:     // 이미 연결이 완료된 상태면 재사용
                return
            case .preparing, .setup:    // 이미 연결 시도 중이면 상태가 변할 때까지 대기
                try await waitForReady(connection: existingConnection)
                return
            default:        // 실패했거나 끊어진 상태면 새로 연결하기 위해 정리
                existingConnection.cancel()
                connections.removeValue(forKey: endpoint)
            }
        }

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connections[endpoint] = connection

        connection.start(queue: self.networkQueue)

        try await waitForReady(connection: connection)
        
        self.logger.info("호스트에 연결 성공")
        self.receiveData(from: connection)
    }

    private func waitForReady(connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.stateUpdateHandler = nil
                    continuation.resume()
                case .failed(let error):
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: error)
                case .cancelled:
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: NWError.posix(.ECANCELED))
                default:
                    break
                }
            }
        }
    }

    func sendData(_ data: Data, to endpoint: NWEndpoint) {
        guard let connection = connections[endpoint] else {
            logger.error("connection이 존재하지 않습니다.")
            return
        }

        logger.info("데이터 전송: \(data.count) bytes")

        connection.send(content: data, isComplete: false, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.logger.error("데이터 전송 실패: \(error.localizedDescription)")
            } else {
                self?.logger.info("데이터 전송 성공")
            }
        })
    }

    // MARK: - Private Methods
    
    private func handleBrowserStateUpdate(_ state: NWBrowser.State) {
        logger.info("브라우저 상태 변경 \(String(describing: state))")

        switch state {
        case .ready:
            logger.info("탐색 준비 완료: 권한 확인")
            onPermissionGranted?()
        case .waiting(let error):
            logger.error("탐색 준비 중: \(error.localizedDescription)")
            onPermissionDeniedOrFailed?(error)
        case .failed(let error):
            logger.error("탐색 준비 실패: \(error.localizedDescription)")
            onPermissionDeniedOrFailed?(error)
        case .cancelled:
            logger.info("탐색 종료")
        default:
            break
        }
    }

    private func handleBrowseResultsChanged(results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        logger.info("탐색 결과 변경: \(results.count) 명의 동료 찾음")

        let peers = results.compactMap { result -> Peer? in
            // 서비스 이름 추출
            guard case .service(let name, _, _, _) = result.endpoint else {
                return nil
            }

            var status: PeerStatus = .available

            if case .bonjour(let txtRecord) = result.metadata {
                if let statusString = txtRecord["status"],
                   let parsedStatus = PeerStatus(rawValue: statusString) {
                    status = parsedStatus
                    logger.info("Parsed peer \(name) with status: \(status.rawValue)")
                }
            }

            return Peer(
                name: name,
                status: status,
                endpoint: result.endpoint,
                latency: nil                    // 탐색 직후부터 latency를 계산할 수 없으므로 초기값 nil
            )
        }

        onPeersUpdated?(Array(peers))
    }

    private func receiveData(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.logger.info("데이터 수신: \(data.count) bytes")
                if let connection = self?.connection {
                    self?.onDataReceived?(data, connection)
                }
            }

            if let error = error {
                self?.logger.error("데이터 수신 실패: \(error.localizedDescription)")
                self?.removeConnection(connection)
                return
            }

            // isComplete가 true여도 connection 상태가 ready면 계속 수신 대기
            if connection.state == .ready {
                self?.receiveData(from: connection)
            } else {
                self?.logger.info("연결 상태가 ready가 아님: \(String(describing: connection.state))")
                self?.removeConnection(connection)
            }
        }
    }

    private func removeConnection(_ connection: NWConnection) {
        connections = connections.filter { $0.value !== connection }
        connection.cancel()
    }
}
