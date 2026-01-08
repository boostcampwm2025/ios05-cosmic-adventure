//
//  NetworkSessionManager.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Observation
import Network
import os

@Observable
public final class NetworkSessionManager: ConnectionSessionProvider {

    // MARK: - Properties

    private var host: HostManaging
    private var client: ClientManaging

    private var hostGranted: Bool? = nil
    private var clientGranted: Bool? = nil
    private var myNickname: String?
    public var nearbyPlayer: [Peer] = []

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var pendingInviteConnections: [String: NWConnection] = [:]

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "NetworkSessionManager")

    // MARK: - Callbacks

    public var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)?
    public var onReceiveInvitationPacket: ((NetworkPacketType, Data) -> Void)?
//    public var onReceiveGamePacket: ((Data, Data) -> Void)?

    // MARK: - Initialization

    public init(host: HostManaging, client: ClientManaging) {
        self.host = host
        self.client = client

        setupHostCallback()
        setupClientCallback()
    }

    public convenience init() {
         self.init(
             host: HostManager(),
             client: ClientManager()
         )
     }

     // MARK: - Public Methods

     public func activate(nickname: String) {
         logger.info("호스팅, 탐색 시작")

         myNickname = nickname

         host.startHosting(nickName: nickname, status: .available)
         client.startBrowsing()
     }

     public func deactive() {
         logger.info("호스팅, 탐색 중단")

         host.stopHosting()
         client.stopBrowsing()

         nearbyPlayer.removeAll()
         myNickname = nil

         hostGranted = nil
         clientGranted = nil

         onPermissionResult = nil
     }

    // MARK: - Private Methods

    private func setupHostCallback() {
        host.onPermissionGranted = { [weak self] in
            self?.hostGranted = true
            self?.checkBothPermission()
        }

        host.onPermissionDeniedOrFailed = { [weak self] error in
            self?.hostGranted = false
            self?.handlePermissionError(error)
        }

        host.onDataReceived = { [weak self] data, connection in
            self?.handleReceivedData(data, from: connection)
        }
    }

    private func setupClientCallback() {
        client.onPermissionGranted = { [weak self] in
            self?.clientGranted = true
            self?.checkBothPermission()
        }

        client.onPermissionDeniedOrFailed = { [weak self] error in
            self?.clientGranted = false
            self?.handlePermissionError(error)
        }

        client.onPeersUpdated = { [weak self] peers in
            guard let self else { return }
            let filteredPeers = peers.filter { $0.name != self.myNickname }

            // UI에 표시될 순서대로 정렬(연결 가능한 순서대로 처리)
            // 추후 변경 가능성 존재
            self.nearbyPlayer = filteredPeers.sorted { peer1, peer2 in
                if peer1.status == .available && peer2.status == .busy {
                    return true
                } else if peer1.status == .busy && peer2.status == .available {
                    return false
                } else {
                    return peer1.name < peer2.name
                }
            }
        }

        client.onDataReceived = { [weak self] data in
            self?.handleReceivedData(data)
        }
    }

    private func handlePermissionError(_ error: Error) {
        let isDenied = (error as NSError).code == -65570

        if isDenied {
            onPermissionResult?(.failure(.denied))
        } else {
            onPermissionResult?(.failure(.unknown))
        }
    }

    private func checkBothPermission() {
        guard let hostGranted,
              let clientGranted else {
            return
        }

        if hostGranted && clientGranted {
            onPermissionResult?(.success(()))
        } else {
            onPermissionResult?(.failure(.unknown))
        }
    }

    private func handleReceivedData(_ data: Data, from connection: NWConnection? = nil) {
        guard let header = try? decoder.decode(NetworkPacketHeader.self, from: data) else { return }

        if header.type == .invite, let connection = connection {
            self.pendingInviteConnections[header.senderIdentifier] = connection
        }

        DispatchQueue.main.async { [weak self] in
            switch header.type {
            case .invite, .accept, .decline, .cancelInvite:
                self?.onReceiveInvitationPacket?(header.type, data)

//            case .gameData:
//                self?.onReceiveGamePacket?(data)
            }
        }
    }

    public func requestInvite<T: NetworkTransferable>(to peer: Peer, packet: T) {
        guard let data = try? encoder.encode(packet) else { return }

        Task {
            do {
                try await client.connectToHost(endpoint: peer.endpoint)
                client.sendData(data)

            } catch {
                logger.error("연결 실패: \(error.localizedDescription)")
            }
        }
    }

    public func replyToInvite<T: NetworkTransferable>(to targetName: String, packet: T) {
        guard let connection = self.pendingInviteConnections[targetName] else { return }
        guard let data = try? encoder.encode(packet) else { return }

        host.sendData(data, to: connection)

        self.pendingInviteConnections.removeValue(forKey: targetName)
    }

    // TODO: 게임 데이터 전송
//    public func send<T: NetworkTransferable>(_ packet: T) {
//        guard let data = try? encoder.encode(packet) else { return }
//    }
}
