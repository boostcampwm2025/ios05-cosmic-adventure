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
public final class NetworkSessionManager: NetworkSessionManaging {

    // MARK: - Properties

    private var host: HostManaging
    private var client: ClientManaging

    private var isActive = false
    private var hostGranted: Bool? = nil
    private var clientGranted: Bool? = nil
    private var myNickname: String?
    public var nearbyPlayer: [Peer] = []

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var pendingInviteConnections: [String: NWConnection] = [:]
    private var activeGameConnection: NWConnection?

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "NetworkSessionManager")

    // MARK: - Callbacks

    public var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)?
    public var onInviteReceived: ((String) -> Void)?
    public var onInviteAccepted: ((String) -> Void)?
    public var onInviteDeclined: ((String) -> Void)?
    public var onInviteCancelled: ((String) -> Void)?
    public var onInputReceived: ((String, Data) -> Void)?
    public var onReadyStatusReceived: ((String) -> Void)?

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

    public func activate(channelId: String?, nickname: String) {
         guard !isActive else { return }
         isActive = true

         logger.info("호스팅, 탐색 시작")

         myNickname = nickname

         host.startHosting(nickName: nickname, status: .available)
         client.startBrowsing()
     }

     public func deactivate() {
         guard isActive else { return }
         isActive = false

         logger.info("호스팅, 탐색 중단")

         host.stopHosting()
         client.stopBrowsing()

         nearbyPlayer.removeAll()
         myNickname = nil

         hostGranted = nil
         clientGranted = nil

         onPermissionResult = nil
     }

    public func sendInvite(to peerName: String) {
        guard let targetPeer = nearbyPlayer.first(where: { $0.name == peerName }) else { return }
        let packet = NetworkPacket(type: .invite, senderIdentifier: myNickname ?? "Unknown")

        sendToPeer(to: targetPeer, packet: packet)
    }

    public func cancelInvite(to peerName: String) {
        guard let targetPeer = nearbyPlayer.first(where: { $0.name == peerName }) else { return }
        let packet = NetworkPacket(type: .inviteCancel, senderIdentifier: myNickname ?? "Unknown")

        sendToPeer(to: targetPeer, packet: packet)
    }

    public func acceptInvite(from peerName: String) {
        let packet = NetworkPacket(type: .inviteAccept, senderIdentifier: myNickname ?? "Unknown")
        replyToPeer(to: peerName, packet: packet)
    }

    public func declineInvite(from peerName: String) {
        let packet = NetworkPacket(type: .inviteDecline, senderIdentifier: myNickname ?? "Unknown")
        replyToPeer(to: peerName, packet: packet)
    }

    public func sendInput<T: Codable>(_ data: T, to targetId: String?) {
        guard let payload = try? encoder.encode(data) else { return }
        let packet = NetworkPacket(
            type: .input,
            senderIdentifier: myNickname ?? "Unknown",
            payload: payload
        )
        guard let encodedPacket = try? encoder.encode(packet) else { return }

        if let connection = self.activeGameConnection {
            connection.send(content: encodedPacket, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("전송 실패: \(error.localizedDescription)")
                }
            })
        }
    }

    public func sendReadyStatus(to peerName: String) {
        guard let targetPeer = nearbyPlayer.first(where: { $0.name == peerName }) else { return }
        let packet = NetworkPacket(type: .gameReady, senderIdentifier: myNickname ?? "Unknown")

        sendToPeer(to: targetPeer, packet: packet)
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
        guard let packet = try? decoder.decode(NetworkPacket.self, from: data) else { return }

        if packet.type == .invite, let connection = connection {
            self.pendingInviteConnections[packet.senderIdentifier] = connection
        }

        DispatchQueue.main.async { [weak self] in
            switch packet.type {
            case .invite:
                self?.onInviteReceived?(packet.senderIdentifier)

            case .inviteAccept:
                if let connection = connection {
                    self?.activeGameConnection = connection
                     self?.pendingInviteConnections.removeValue(forKey: packet.senderIdentifier)
                }
                self?.onInviteAccepted?(packet.senderIdentifier)

            case .inviteDecline:
                self?.onInviteDeclined?(packet.senderIdentifier)

            case .inviteCancel:
                self?.onInviteCancelled?(packet.senderIdentifier)

            case .input:
                if let payload = packet.payload {
                    self?.onInputReceived?(packet.senderIdentifier, payload)
                }
            case .gameReady:
                self?.onReadyStatusReceived?(packet.senderIdentifier)
            }
        }
    }

    private func sendToPeer(to peer: Peer, packet: NetworkPacket) {
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

    private func replyToPeer(to targetName: String, packet: NetworkPacket) {
        guard let connection = self.pendingInviteConnections[targetName] else { return }

        guard let data = try? encoder.encode(packet) else { return }
        host.sendData(data, to: connection)

        self.pendingInviteConnections.removeValue(forKey: targetName)
    }
}
