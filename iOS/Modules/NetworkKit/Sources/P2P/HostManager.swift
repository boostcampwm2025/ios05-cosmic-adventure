//
//  HostManager.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Network
import os

final class HostManager: HostManaging, ConnectionHandling {
    
    // MARK: - Properties
    
    private let serviceType = "_cosmicadventure._tcp"
    private let networkQueue = DispatchQueue(label: "com.cosmicadventure.host")

    private var listener: NWListener?
    private var connections: [NWConnection] = []

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "HostManager")
    var connectionLogger: Logger { logger }

    // MARK: - Callbacks

    var onPermissionGranted: (() -> Void)?
    var onPermissionDeniedOrFailed: ((Error) -> Void)?
    var onDataReceived: ((Data, NWConnection) -> Void)?
    var onConnectionFailed: ((NWConnection) -> Void)?
    
    // MARK: - Initialization

    init() { }

    deinit {
        stopHosting()
        logger.info("HostManager deinit")
    }

    // MARK: - Public Methods

    func startHosting(nickName: String, status: PeerStatus, sessionId: UUID, characterRawValue: String) {
        logger.info("호스팅 시작 nickName: \(nickName), status: \(status.rawValue)")

        let txtRecord = NWTXTRecord([
            "status": status.rawValue,
            "nickname": nickName,
            "sessionId": sessionId.uuidString,
            "character": characterRawValue
        ])
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let framerOptions = NWProtocolFramer.Options(definition: LengthPrefixFramer.definition)
        parameters.defaultProtocolStack.applicationProtocols.insert(framerOptions, at: 0)

        let service = NWListener.Service(name: nickName, type: serviceType, txtRecord: txtRecord)
        
        do {
            listener = try NWListener(service: service, using: parameters)

            listener?.stateUpdateHandler = { [weak self] state in
                self?.handleListenerStateUpdate(state)
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener?.start(queue: networkQueue)

        } catch {
            logger.error("리스너 생성 실패: \(error.localizedDescription)")
            onPermissionDeniedOrFailed?(error)
        }
    }

    func stopHosting() {
        logger.info("호스팅 종료")

        connections.forEach { $0.cancel() }
        connections.removeAll()

        listener?.cancel()
        listener = nil
    }

    // MARK: - Private Methods

    private func handleListenerStateUpdate(_ state: NWListener.State) {
        logger.info("리스너 상태 변경: \(String(describing: state))")

        switch state {
        case .ready:
            logger.info("리스너 준비 완료(권한 확인)")
            onPermissionGranted?()
        case .waiting(let error):
            print(error.debugDescription)
            onPermissionDeniedOrFailed?(error)
        case .failed(let error):
            logger.error("리스너 준비 실패: \(error.localizedDescription)")
            onPermissionDeniedOrFailed?(error)
        case .cancelled:
            logger.info("리스너 취소")

        default:
            break
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            self?.logger.info("연결 상태 변경: \(String(describing: state))")

            switch state {
            case .ready:
                self?.logger.info("연결 준비 완료")
                self?.receiveData(from: connection)
            case .failed(let error):
                self?.logger.error("연결 실패: \(error.localizedDescription)")
                self?.onConnectionFailed?(connection)
                self?.removeConnection(connection)
            default:
                return
            }
        }

        connection.start(queue: networkQueue)
    }

    func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
        connection.cancel()
    }
}
