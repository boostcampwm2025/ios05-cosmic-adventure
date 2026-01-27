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
    let me: LobbyExplorer
    let peer: LobbyExplorer

    private(set) var isMeReady: Bool = false
    private(set) var isPeerReady: Bool = false

    private(set) var message: String = ""
    private(set) var progress: Double = 0.0

    private(set) var networkMode: NetworkMode = .local

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring

    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?

    init(
        me: LobbyExplorer,
        peer: LobbyExplorer,
        connectivityMonitor: ConnectivityMonitoring,
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging?
    ) {
        self.me = me
        self.peer = peer
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager

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
                self?.handleConnectivityChange(isConnected: isConnected)
            }
        }
        connectivityMonitor.start()
        networkMode = connectivityMonitor.isConnected ? .remote : .local
    }

    private func handleConnectivityChange(isConnected: Bool) {
        if isConnected {
            networkMode = .remote
        } else {
            networkMode = .local
        }
    }

    private func setupP2PCallbacks() {
        networkSessionManager.onReadyStatusReceived = { [weak self] senderName in
            guard let self else { return }

            guard senderName == self.peer.displayName else { return }

            Task { @MainActor in
                self.handlePeerReady()
            }
        }
    }

    private func setupWebSocketCallbacks() {
        webSocketSessionManager?.onReadyStatusReceived = { [weak self] senderName in
            guard let self else { return }

            guard senderName == self.peer.displayName else { return }

            Task { @MainActor in
                self.handlePeerReady()
            }
        }
    }

    private func sendReadySignal() {
        switch networkMode {
        case .local:
            networkSessionManager.sendReadyStatus(to: peer.displayName)

        case .remote:
            webSocketSessionManager?.sendReadyStatus(to: peer.displayName)
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
