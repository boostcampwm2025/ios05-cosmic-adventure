//
//  ConnectionHandling+Default.swift
//  NetworkKit
//
//  Created by 강윤서 on 2/5/26.
//

import Foundation
import Network

extension ConnectionHandling {

    // MARK: - Receive

    func receiveData(from connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.connectionLogger.info("데이터 수신: \(data.count) bytes")
                self?.onDataReceived?(data, connection)
            }

            if let error = error {
                self?.connectionLogger.error("데이터 수신 실패: \(error.localizedDescription)")
                self?.onConnectionFailed?(connection)
                self?.removeConnection(connection)
                return
            }

            if connection.state == .ready {
                self?.receiveData(from: connection)
            } else {
                self?.connectionLogger.info("연결 상태가 ready가 아님: \(String(describing: connection.state))")
                self?.onConnectionFailed?(connection)
                self?.removeConnection(connection)
            }
        }
    }

    // MARK: - Send

    func sendData(_ data: Data, to connection: NWConnection, completion: ((NWError?) -> Void)? = nil) {
        connectionLogger.info("데이터 전송: \(data.count) bytes")

        connection.send(content: data, isComplete: true, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.connectionLogger.error("데이터 전송 실패: \(error.localizedDescription)")
            } else {
                self?.connectionLogger.info("데이터 전송 성공")
            }
            completion?(error)
        })
    }
}
