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
    private var lastPingTimestamps: [String: Date] = [:]
    private var pingTimer: Timer?

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "NetworkSessionManager")

    // MARK: - Callbacks

    public var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)?
    public var onInviteReceived: ((String) -> Void)?
    public var onInviteAccepted: ((String) -> Void)?
    public var onInviteDeclined: ((String) -> Void)?
    public var onInviteCancelled: ((String) -> Void)?
    public var onInputReceived: ((String, Data) -> Void)?
    public var onPeersUpdated: (([Peer]) -> Void)?
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

         logger.info("P2P 탐색 시작")

         myNickname = nickname

         host.startHosting(nickName: nickname, status: .available)
         client.startBrowsing()
         startPingTimer()
     }

     public func deactivate() {
         guard isActive else { return }
         isActive = false

         logger.info("P2P 탐색 종료")

         host.stopHosting()
         client.stopBrowsing()
         stopPingTimer()

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
            print("📡 [NetworkSessionManager] 원본 피어 발견: \(peers.count)명")
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
            self.onPeersUpdated?(self.nearbyPlayer)
            print("📡 [NetworkSessionManager] 필터링 후 피어: \(self.nearbyPlayer.count)명")
        }

        client.onDataReceived = { [weak self] data, connection in
            self?.handleReceivedData(data, from: connection)
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

    /// 5초마다 탐색된 디바이스에 ping 전송
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sendPingsToAll()
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPingsToAll() {
        for player in nearbyPlayer {
            let packet = NetworkPacket(type: .ping, senderIdentifier: myNickname ?? "Unknown")
            lastPingTimestamps[player.name] = Date()
            sendToPeer(to: player, packet: packet)
        }
    }

    private func handleReceivedData(_ data: Data, from connection: NWConnection? = nil) {
        guard let packet = try? decoder.decode(NetworkPacket.self, from: data) else { return }

        if packet.type == .invite, let connection = connection {
            self.pendingInviteConnections[packet.senderIdentifier] = connection
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            switch packet.type {
            case .ping:
                let pongPacket = NetworkPacket(type: .pong, senderIdentifier: self.myNickname ?? "Unknown")
                guard let encodedPong = try? self.encoder.encode(pongPacket) else { return }
                
                if let connection = connection {
                    self.host.sendData(encodedPong, to: connection)
                }

            case .pong:
                if let sendDate = self.lastPingTimestamps[packet.senderIdentifier] {
                    let latency = Date().timeIntervalSince(sendDate) * 1000.0
                    self.updatePeerLatency(name: packet.senderIdentifier, latency: latency)
                    self.lastPingTimestamps.removeValue(forKey: packet.senderIdentifier)
                }

            case .invite:
                self.onInviteReceived?(packet.senderIdentifier)

            case .inviteAccept:
                if let connection = connection {
                    self.activeGameConnection = connection
                    self.pendingInviteConnections.removeValue(forKey: packet.senderIdentifier)
                }
                self.onInviteAccepted?(packet.senderIdentifier)

            case .inviteDecline:
                self.onInviteDeclined?(packet.senderIdentifier)

            case .inviteCancel:
                self.onInviteCancelled?(packet.senderIdentifier)

            case .input:
                if let payload = packet.payload {
                    self.onInputReceived?(packet.senderIdentifier, payload)
                }
            case .gameReady:
                self.onReadyStatusReceived?(packet.senderIdentifier)
            }
        }
    }

    /// ping/pong 결과에 따라 latency 상태 업데이트
    private func updatePeerLatency(name: String, latency: Double) {
        if let index = nearbyPlayer.firstIndex(where: { $0.name == name }) {
            nearbyPlayer[index].latency = latency
            onPeersUpdated?(nearbyPlayer)
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
        
        // TODO: 발신 보장되었을 때 동작하도록 수정하기
        // 초대받은 쪽(Invitee)도 즉시 게임 연결을 확정
        if packet.type == .inviteAccept {
            self.activeGameConnection = connection
        }

        self.pendingInviteConnections.removeValue(forKey: targetName)
    }
}
