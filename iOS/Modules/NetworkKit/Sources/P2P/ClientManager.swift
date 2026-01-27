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
    private var connections: [NWEndpoint: [ConnectionKind: NWConnection]] = [:]

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "ClientManager")

    // MARK: - Callbacks

    var onPermissionGranted: (() -> Void)?
    var onPermissionDeniedOrFailed: ((Error) -> Void)?
    var onPeersUpdated: (([NetworkPeer]) -> Void)?
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

        browser = NWBrowser(for: .bonjourWithTXTRecord(type: serviceType, domain: nil), using: parameters)
        
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

        connections.values.flatMap { $0.values }.forEach { $0.cancel() }
        connections.removeAll()

        browser?.cancel()
        browser = nil
    }

    func connectToHost(endpoint: NWEndpoint, kind: ConnectionKind) async throws -> NWConnection {
        if let existingConnection = connections[endpoint]?[kind] {
            switch existingConnection.state {
            case .ready:
                return existingConnection
            case .preparing, .setup:
                return existingConnection  // 이미 연결 시도 중이면 그냥 반환 (기존 receiveData가 동작 중)
            default:
                existingConnection.cancel()
                connections[endpoint]?[kind] = nil
            }
        }

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let connection = NWConnection(to: endpoint, using: parameters)
        if connections[endpoint] == nil {
            connections[endpoint] = [:]
        }
        connections[endpoint]?[kind] = connection

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.receiveData(from: connection)
            case .failed(let error):
                self.logger.error("연결 실패: \(error.localizedDescription)")
                self.removeConnection(connection)
            case .cancelled:
                self.removeConnection(connection)
            default:
                self.logger.info("연결 상태: \(String(describing: state))")
            }
        }

        connection.start(queue: self.networkQueue)
        return connection
    }

    func sendData(_ data: Data, to endpoint: NWEndpoint, kind: ConnectionKind) {
        guard let connection = connections[endpoint]?[kind] else {
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

        let peers = results.compactMap { result -> NetworkPeer? in
            // 서비스 이름 추출
            guard case .service(let name, _, _, _) = result.endpoint else {
                return nil
            }

            var status: PeerStatus = .available
            var nickname = name
            var sessionId: UUID?

            if case .bonjour(let txtRecord) = result.metadata {
                if let statusString = txtRecord["status"],
                   let parsedStatus = PeerStatus(rawValue: statusString) {
                    status = parsedStatus
                    logger.info("Parsed peer \(name) with status: \(status.rawValue)")
                }
                if let nicknameString = txtRecord["nickname"] {
                    nickname = nicknameString
                }
                if let sessionIdString = txtRecord["sessionId"] {
                    sessionId = UUID(uuidString: sessionIdString)
                }
            }

            guard let sessionId else { return nil }

            return NetworkPeer(
                sessionId: sessionId,
                name: nickname,
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
                self?.onDataReceived?(data, connection)
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
        let endpoints = Array(connections.keys)
        for endpoint in endpoints {
            guard let dict = connections[endpoint] else { continue }
            let kinds = Array(dict.keys)
            for kind in kinds {
                if connections[endpoint]?[kind] === connection {
                    connections[endpoint]?[kind] = nil
                }
            }
            if connections[endpoint]?.isEmpty == true {
                connections[endpoint] = nil
            }
        }
        connection.cancel()
    }
}
