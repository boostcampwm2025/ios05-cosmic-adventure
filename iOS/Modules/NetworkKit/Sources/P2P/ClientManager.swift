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
    private var connection: NWConnection?

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

        connection?.cancel()
        connection = nil

        browser?.cancel()
        browser = nil
    }

    func connectToHost(endpoint: NWEndpoint) async throws {
        connection?.cancel()

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection

        let stateStream = AsyncStream<NWConnection.State> { continuation in
            connection.stateUpdateHandler = { state in
                continuation.yield(state)
            }

            connection.start(queue: self.networkQueue)
        }

        for await state in stateStream {
            self.logger.info("연결 상태 변경: \(String(describing: state))")

            switch state {
            case .ready:
                self.logger.info("호스트에 연결 성공")
                self.receiveData()
                return

            case .failed(let error):
                self.logger.error("연결 실패: \(error.localizedDescription)")
                throw error

            case .cancelled:
                throw NWError.posix(.ECANCELED)

            default:
                break
            }
        }
    }

    func sendData(_ data: Data) {
        guard let connection = connection else {
            logger.error("connection이 존재하지 않습니다.")
            return
        }

        logger.info("데이터 전송: \(data.count) bytes")

        connection.send(content: data, completion: .contentProcessed { [weak self] error in
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

    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.logger.info("데이터 수신: \(data.count) bytes")
                if let connection = self?.connection {
                    self?.onDataReceived?(data, connection)
                }
            }

            if let error = error {
                self?.logger.error("데이터 수신 실패: \(error.localizedDescription)")
                return
            }

            if !isComplete {
                self?.receiveData()
            }
        }
    }
}
