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
    private var currentCharacterRawValue: String?

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

    func updateExploration(mode: NetworkMode, channelId: String?, nickname: String, characterRawValue: String) {
        let needsRestart = currentMode != mode
            || currentChannelId != channelId
            || currentNickname != nickname
            || currentCharacterRawValue != characterRawValue
        
        currentMode = mode
        currentChannelId = channelId
        currentNickname = nickname
        currentCharacterRawValue = characterRawValue
        
        if needsRestart && isAppActive {
            deactivateAll()
            activateIfNeeded()
        }
    }

    func stopExploration() {
        currentMode = nil
        currentChannelId = nil
        currentNickname = nil
        currentCharacterRawValue = nil
        deactivateAll()
    }

    private func activateIfNeeded() {
        guard let mode = currentMode,
              let nickname = currentNickname,
              let characterRawValue = currentCharacterRawValue else { return }

        switch mode {
        case .local:
            networkSessionManager.activate(
                channelId: nil,
                nickname: nickname,
                characterRawValue: characterRawValue
            )
        case .remote:
            guard let channelId = currentChannelId else { return }
            webSocketSessionManager?.activate(
                channelId: channelId,
                nickname: nickname,
                characterRawValue: characterRawValue
            )
        }
    }

    private func deactivateAll() {
        networkSessionManager.deactivate()
        webSocketSessionManager?.deactivate()
    }
}
