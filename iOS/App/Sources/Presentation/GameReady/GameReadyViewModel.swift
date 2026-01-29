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
    let localPlayer: PlayerInfo
    let remotePlayer: PlayerInfo?
    let isNetwork: Bool

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring
    
    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?

    @ObservationIgnored
    private var readyRetryTimer: Timer?

    private(set) var isMeReady: Bool = false
    private(set) var isPeerReady: Bool = false

    private(set) var message: String = ""
    private(set) var progress: Double = 0.0

    private(set) var networkMode: NetworkMode
    
    let appEntryManager: AppEntryManager

    init(
        localPlayer: PlayerInfo,
        remotePlayer: PlayerInfo?,
        isNetwork: Bool,
        connectivityMonitor: ConnectivityMonitoring,
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging?,
        appEntryManager: AppEntryManager
    ) {
        self.localPlayer = localPlayer
        self.remotePlayer = remotePlayer
        self.isNetwork = isNetwork
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.appEntryManager = appEntryManager
        self.networkMode = isNetwork ? .remote : .local

        setupConnectivityMonitor()
    }

    deinit {
        readyRetryTimer?.invalidate()
    }

    func setMyReady() {
        guard !isMeReady else { return }
        isMeReady = true

        setupP2PCallbacks()
        setupWebSocketCallbacks()

        // 본인의 Ready를 UI에 즉시 반영
        updateProgressUI()

        if remotePlayer == nil {
            Task {
                // TODO: game map load 되는 시점으로 변경
                try? await Task.sleep(for: .seconds(3))
                self.isPeerReady = true // 3초 뒤 상대도 Ready
                self.updateProgressUI() // 둘 다 Ready
            }
        } else {
            startReadySignalTimer()
        }
    }

    func checkAllReady() -> Bool {
        return isMeReady && isPeerReady
    }

    func stopTimer() {
        readyRetryTimer?.invalidate()
        readyRetryTimer = nil
    }

    private func startReadySignalTimer() {
        readyRetryTimer?.invalidate()

        readyRetryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.sendReadySignal()
            }
        }

        readyRetryTimer?.fire()
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

        if isNetwork {
            networkMode = connectivityMonitor.isConnected ? .remote : .local
        }
    }

    private func setupP2PCallbacks() {
        networkSessionManager.onReadyStatusReceived = { [weak self] senderId in
            guard let self else { return }
            guard let remoteId = remotePlayer?.id,
                    senderId == remoteId else { return }

            Task { @MainActor in
                self.handlePeerReady()
            }
        }
    }

    private func setupWebSocketCallbacks() {
        webSocketSessionManager?.onReadyStatusReceived = { [weak self] senderId in
            guard let self else { return }
            guard let remoteId = self.remotePlayer?.id,
                    senderId == remoteId else { return }

            Task { @MainActor in
                self.handlePeerReady()
            }
        }
    }

    private func sendReadySignal() {
        guard let remoteId = remotePlayer?.id else { return }

        switch networkMode {
        case .local:
            networkSessionManager.sendReadyStatus(to: remoteId)

        case .remote:
            webSocketSessionManager?.sendReadyStatus(to: remoteId)
        }
    }

    private func handlePeerReady() {
        guard !isPeerReady else { return }

        isPeerReady = true
        updateProgressUI()
    }

    private func updateProgressUI() {
        // 1인 모드
        if remotePlayer == nil {
            if isMeReady && isPeerReady {
                progress = 1.0
                message = L10N.GameReady.soloReadyMessage
            } else {
                progress = 0.5
                message = L10N.GameReady.soloPreparingMessage
            }
            return
        }

        //  2인 모드
        if isMeReady && isPeerReady {
            progress = 1.0
            message = L10N.GameReady.allReadyMessage
        } else if isMeReady {
            progress = 0.5
            message = L10N.GameReady.waitingForPeerMessage
        } else {
            progress = 0.0
            message = L10N.GameReady.connectingMessage
        }
    }
}
