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
    public var nearbyPlayer: [NetworkPeer] = []
    private var localSessionId: UUID = UUID()

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var pendingInviteConnections: [UUID: NWConnection] = [:]
    private var activeGameConnection: NWConnection?
    private var lastPingTimestamps: [UUID: Date] = [:]
    private var pingTimer: Timer?
    private var peerById: [UUID: NetworkPeer] = [:]

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "NetworkSessionManager")

    // MARK: - Callbacks

    public var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)?
    public var onInviteReceived: ((UUID) -> Void)?
    public var onInviteAccepted: ((UUID) -> Void)?
    public var onInviteDeclined: ((UUID) -> Void)?
    public var onInviteCancelled: ((UUID) -> Void)?
    public var onInputReceived: ((UUID, Data) -> Void)?
    public var onPeersUpdated: (([NetworkPeer]) -> Void)?
    public var onReadyStatusReceived: ((UUID) -> Void)?
    public var onVideoReceived: ((UUID, Data) -> Void)?

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
         localSessionId = UUID()

         host.startHosting(nickName: nickname, status: .available, sessionId: localSessionId)
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
         peerById.removeAll()
         myNickname = nil

         hostGranted = nil
         clientGranted = nil

         onPermissionResult = nil
     }

    public func sendInvite(to targetId: UUID) {
        guard let targetPeer = peerById[targetId] else { return }
        let packet = NetworkPacket(type: .invite, senderIdentifier: localSessionId.uuidString)

        sendToPeer(to: targetPeer, packet: packet)
    }

    public func cancelInvite(to targetId: UUID) {
        guard let targetPeer = peerById[targetId] else { return }
        let packet = NetworkPacket(type: .inviteCancel, senderIdentifier: localSessionId.uuidString)

        sendToPeer(to: targetPeer, packet: packet)
    }

    public func acceptInvite(from targetId: UUID) {
        let packet = NetworkPacket(type: .inviteAccept, senderIdentifier: localSessionId.uuidString)
        replyToPeer(to: targetId, packet: packet)
    }

    public func declineInvite(from targetId: UUID) {
        let packet = NetworkPacket(type: .inviteDecline, senderIdentifier: localSessionId.uuidString)
        replyToPeer(to: targetId, packet: packet)
    }

    public func sendInput<T: Codable>(_ data: T, to targetId: UUID?) {
        guard let payload = try? encoder.encode(data) else { return }
        let packet = NetworkPacket(
            type: .input,
            senderIdentifier: localSessionId.uuidString,
            payload: payload
        )
        guard let encodedPacket = try? encoder.encode(packet) else { return }

        if let connection = self.activeGameConnection {
            connection.send(content: encodedPacket, isComplete: false, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("전송 실패: \(error.localizedDescription)")
                }
            })
        }
    }

    public func sendReadyStatus(to targetId: UUID) {
        guard let targetPeer = peerById[targetId] else { return }
        let packet = NetworkPacket(type: .gameReady, senderIdentifier: localSessionId.uuidString)

        sendToPeer(to: targetPeer, packet: packet)
    }

    public func sendVideo(data: Data) {
        let packet = NetworkPacket(
            type: .videoFrame,
            senderIdentifier: localSessionId.uuidString,
            payload: data
        )

        guard let encodedPacket = try? encoder.encode(packet) else { return }

        if let connection = self.activeGameConnection {
            connection.send(content: encodedPacket, isComplete: false, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("비디오 전송 실패: \(error.localizedDescription)")
                }
            })
        }
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
            logger.debug("📡 [NetworkSessionManager] 원본 피어 발견: \(peers.count)명")
            let filteredPeers = peers.filter { $0.sessionId != self.localSessionId }

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
            self.peerById = Dictionary(uniqueKeysWithValues: self.nearbyPlayer.map { ($0.sessionId, $0) })
            self.onPeersUpdated?(self.nearbyPlayer)
            logger.debug("📡 [NetworkSessionManager] 필터링 후 피어: \(self.nearbyPlayer.count)명")
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
            let packet = NetworkPacket(type: .ping, senderIdentifier: localSessionId.uuidString)
            lastPingTimestamps[player.sessionId] = Date()
            sendToPeer(to: player, packet: packet)
        }
    }

    private func handleReceivedData(_ data: Data, from connection: NWConnection) {
        guard let packet = try? decoder.decode(NetworkPacket.self, from: data) else { return }

        guard let senderId = UUID(uuidString: packet.senderIdentifier) else { return }

        if packet.type == .invite {
            self.pendingInviteConnections[senderId] = connection
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            switch packet.type {
            case .ping:
                let pongPacket = NetworkPacket(type: .pong, senderIdentifier: localSessionId.uuidString)
                guard let encodedPong = try? self.encoder.encode(pongPacket) else { return }
                host.sendData(encodedPong, to: connection)

            case .pong:
                if let sendDate = lastPingTimestamps[senderId] {
                    let latency = Date().timeIntervalSince(sendDate) * 1000.0
                    updatePeerLatency(sessionId: senderId, latency: latency)
                    lastPingTimestamps.removeValue(forKey: senderId)
                }

            case .invite:
                onInviteReceived?(senderId)

            case .inviteAccept:
                activeGameConnection = connection
                pendingInviteConnections.removeValue(forKey: senderId)
                onInviteAccepted?(senderId)

            case .inviteDecline:
                onInviteDeclined?(senderId)

            case .inviteCancel:
                onInviteCancelled?(senderId)

            case .input:
                if let payload = packet.payload {
                    onInputReceived?(senderId, payload)
                }

            case .gameReady:
                onReadyStatusReceived?(senderId)

            case .videoFrame:
                if let payload = packet.payload {
                    onVideoReceived?(senderId, payload)
                }
            }
        }
    }

    /// ping/pong 결과에 따라 latency 상태 업데이트
    private func updatePeerLatency(sessionId: UUID, latency: Double) {
        if let index = nearbyPlayer.firstIndex(where: { $0.sessionId == sessionId }) {
            nearbyPlayer[index].latency = latency
            onPeersUpdated?(nearbyPlayer)
        }
    }

    private func sendToPeer(to peer: NetworkPeer, packet: NetworkPacket) {
        guard let data = try? encoder.encode(packet) else { return }

        Task {
            do {
                try await client.connectToHost(endpoint: peer.endpoint)
                client.sendData(data, to: peer.endpoint)
            } catch {
                logger.error("연결 실패: \(error.localizedDescription)")
            }
        }
    }

    private func replyToPeer(to targetId: UUID, packet: NetworkPacket) {
        guard let connection = self.pendingInviteConnections[targetId] else { return }

        guard let data = try? encoder.encode(packet) else { return }
        host.sendData(data, to: connection)
        
        // TODO: 발신 보장되었을 때 동작하도록 수정하기
        // 초대받은 쪽(Invitee)도 즉시 게임 연결을 확정
        if packet.type == .inviteAccept {
            self.activeGameConnection = connection
        }

        if packet.type == .inviteAccept {
            self.activeGameConnection = connection
        }

        self.pendingInviteConnections.removeValue(forKey: targetId)
    }
}
