//
//  ClientManager.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Network
import os

final class ClientManager: ClientManaging, ConnectionHandling, @unchecked Sendable {

    // MARK: - Properties
    
    private let serviceType = "_cosmicadventure._tcp"
    private let networkQueue = DispatchQueue(label: "com.cosmicadventure.client")

    private var browser: NWBrowser?
    private var connections: [NWEndpoint: [ConnectionKind: NWConnection]] = [:]

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "ClientManager")
    var connectionLogger: Logger { logger }

    // MARK: - Callbacks

    var onPermissionGranted: (() -> Void)?
    var onPermissionDeniedOrFailed: ((Error) -> Void)?
    var onPeersUpdated: (([NetworkPeer]) -> Void)?
    var onDataReceived: ((Data, NWConnection) -> Void)?
    var onConnectionFailed: ((NWConnection) -> Void)?

    // MARK: - Initialization

    init() { }

    deinit {
        stopBrowsing()
        logger.info("ClientManager deinit")
    }

    // MARK: - Public Methods

    func startBrowsing() {
        networkQueue.async { [weak self] in
            guard let self = self else { return }
            logger.info("탐색 시작: \(self.serviceType)")

            let parameters = NWParameters()
            parameters.includePeerToPeer = true

            browser = NWBrowser(for: .bonjourWithTXTRecord(type: serviceType, domain: nil),
                                using: parameters)

            browser?.browseResultsChangedHandler = { [weak self] results, changes in
                self?.handleBrowseResultsChanged(results: results, changes: changes)
            }

            browser?.stateUpdateHandler = { [weak self] state in
                self?.handleBrowserStateUpdate(state)
            }

            browser?.start(queue: networkQueue)
        }
    }

    func stopBrowsing() {
        networkQueue.async { [weak self] in
            guard let self = self else { return }
            logger.info("탐색 종료")

            connections.values.flatMap { $0.values }.forEach { $0.cancel() }
            connections.removeAll()

            browser?.cancel()
            browser = nil
        }
    }

    func connectToHost(endpoint: NWEndpoint, kind: ConnectionKind) async throws -> NWConnection {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NWConnection, Error>) in

            networkQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                var hasResumed = false

                if let existingConnection = self.connections[endpoint]?[kind] {
                    switch existingConnection.state {
                    case .ready:
                        continuation.resume(returning: existingConnection)
                        return
                    case .preparing, .setup:
                        continuation.resume(returning: existingConnection)
                        return
                    default:
                        existingConnection.cancel()
                        self.connections[endpoint]?[kind] = nil
                    }
                }

                let parameters = NWParameters.tcp
                parameters.includePeerToPeer = true
                let framerOptions = NWProtocolFramer.Options(definition: LengthPrefixFramer.definition)
                parameters.defaultProtocolStack.applicationProtocols.insert(framerOptions, at: 0)
                let connection = NWConnection(to: endpoint, using: parameters)

                if self.connections[endpoint] == nil {
                    self.connections[endpoint] = [:]
                }
                self.connections[endpoint]?[kind] = connection

                connection.stateUpdateHandler = { [weak self] state in
                    guard let self = self else {
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: CancellationError())
                        }
                        return
                    }

                    switch state {
                    case .ready:
                        self.receiveData(from: connection)
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(returning: connection)
                        }
                    case .failed(let error):
                        self.logger.error("연결 실패: \(error.localizedDescription)")
                        self.onConnectionFailed?(connection)
                        self.removeConnection(connection)
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: error)
                        }
                    case .cancelled:
                        self.onConnectionFailed?(connection)
                        self.removeConnection(connection)
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: CancellationError())
                        }
                    default:
                        self.logger.info("연결 상태: \(String(describing: state))")
                    }
                }

                connection.start(queue: self.networkQueue) 
            }
        }
    }

    func sendData(_ data: Data, to endpoint: NWEndpoint, kind: ConnectionKind) {
        networkQueue.async { [weak self] in
            guard let self,
                  let connection = self.connections[endpoint]?[kind] else {
                self?.logger.error("connection이 존재하지 않습니다.")
                return
            }

            self.sendData(data, to: connection)
        }
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
            var characterRawValue = ""

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
                if let characterString = txtRecord["character"] {
                    characterRawValue = characterString
                }
            }

            guard let sessionId else { return nil }

            return NetworkPeer(
                sessionId: sessionId,
                nickname: nickname,
                characterRawValue: characterRawValue,
                status: status,
                endpoint: result.endpoint,
                latency: nil
            )
        }

        onPeersUpdated?(Array(peers))
    }

    func removeConnection(_ connection: NWConnection) {
        networkQueue.async { [weak self] in
            guard let self else { return }
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
}
