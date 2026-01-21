//
//  NetworkExplorationCoordinator.swift
//  App
//
//  Created by 영빈 on 1/22/26.
//

import NetworkKit

@MainActor
final class NetworkExplorationCoordinator {
    private let networkSessionManager: NetworkSessionManaging
    private let webSocketSessionManager: WebSocketSessionManaging?

    private var isAppActive = true
    private var currentMode: NetworkMode?
    private var currentChannelId: String?
    private var currentNickname: String?

    init(
        networkSessionManager: NetworkSessionManaging,
        webSocketSessionManager: WebSocketSessionManaging?
    ) {
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
    }

    func setAppActive(_ isActive: Bool) {
        guard isAppActive != isActive else { return }
        isAppActive = isActive
        
        if isActive {
            activateIfNeeded()
        } else {
            deactivateAll()
        }
    }

    func updateExploration(mode: NetworkMode, channelId: String?, nickname: String) {
        let needsRestart = currentMode != mode || currentChannelId != channelId || currentNickname != nickname
        
        currentMode = mode
        currentChannelId = channelId
        currentNickname = nickname
        
        if needsRestart && isAppActive {
            deactivateAll()
            activateIfNeeded()
        }
    }

    func stopExploration() {
        currentMode = nil
        currentChannelId = nil
        currentNickname = nil
        deactivateAll()
    }

    private func activateIfNeeded() {
        guard let mode = currentMode, let nickname = currentNickname else { return }

        switch mode {
        case .local:
            networkSessionManager.activate(nickname: nickname)
        case .remote:
            guard let channelId = currentChannelId else { return }
            webSocketSessionManager?.activate(channelId: channelId, nickname: nickname)
        }
    }

    private func deactivateAll() {
        networkSessionManager.deactivate()
        webSocketSessionManager?.deactivate()
    }
}
