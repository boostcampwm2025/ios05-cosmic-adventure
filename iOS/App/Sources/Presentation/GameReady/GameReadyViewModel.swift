//
//  GameReadyViewModel.swift
//  App
//
//  Created by soyoung on 1/15/26.
//

import Foundation
import NetworkKit

@MainActor
@Observable
final class GameReadyViewModel {
    let me: PlayerInfo
    let peer: PlayerInfo?
    let isNetwork: Bool

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring
    
    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?

    private(set) var isMeReady: Bool = false
    private(set) var isPeerReady: Bool = false

    private(set) var message: String = ""
    private(set) var progress: Double = 0.0

    private(set) var networkMode: NetworkMode

    init(
        me: PlayerInfo,
        peer: PlayerInfo?,
        isNetwork: Bool,
        connectivityMonitor: ConnectivityMonitoring,
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging?
    ) {
        self.me = me
        self.peer = peer
        self.isNetwork = isNetwork
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.networkMode = isNetwork ? .remote : .local

        setupConnectivityMonitor()
        setupP2PCallbacks()
        setupWebSocketCallbacks()
    }

    func setMyReady() {
        guard !isMeReady else { return }

        isMeReady = true
        updateProgressUI()

        sendReadySignal()
    }

    func checkAllReady() -> Bool {
        return isMeReady && isPeerReady
    }

    private func setupConnectivityMonitor() {
        connectivityMonitor.onStatusChanged = { [weak self] isConnected in
            Task { @MainActor in
                if self?.isNetwork == true {
                    self?.networkMode = isConnected ? .remote : .local
                }
            }
        }
        connectivityMonitor.start()
    }

    private func setupP2PCallbacks() {
        networkSessionManager.onReadyStatusReceived = { [weak self] senderId in
            guard let self else { return }
            guard senderId == self.peer.id else { return }

            Task { @MainActor in
                self.handlePeerReady()
            }
        }
    }

    private func setupWebSocketCallbacks() {
        webSocketSessionManager?.onReadyStatusReceived = { [weak self] senderId in
            guard let self else { return }
            guard senderId == self.peer.id else { return }

            Task { @MainActor in
                self.handlePeerReady()
            }
        }
    }

    private func sendReadySignal() {
        switch networkMode {
        case .local:
            networkSessionManager.sendReadyStatus(to: peer.id)

        case .remote:
            webSocketSessionManager?.sendReadyStatus(to: peer.id)
        }
    }

    private func handlePeerReady() {
        guard !isPeerReady else { return }

        isPeerReady = true
        updateProgressUI()
    }

    private func updateProgressUI() {
        // 한 명 준비되면 50%, 둘 다 되면 100%
        if isMeReady && isPeerReady {
            progress = 1.0
            message = L10N.GameReady.allReadyMessage

        } else if isMeReady {
            progress = 0.5
            message = L10N.GameReady.waitingForPeerMessage

        } else if isPeerReady {
            progress = 0.5
            message = L10N.GameReady.peerWaitingMessage

        } else {
            progress = 0.0
            message = L10N.GameReady.connectingMessage
        }
    }
}
