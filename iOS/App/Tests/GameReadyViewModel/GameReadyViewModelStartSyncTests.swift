//
//  GameReadyViewModelStartSyncTests.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 2/5/26.
//

import Foundation
import NetworkKit
import XCTest
@testable import App

@MainActor
final class GameReadyViewModelStartSyncTests: XCTestCase {

    func testHostSendsStartAtOverWebSocketOnce() async throws {
        let localId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let remoteId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let (viewModel, webSocket, _) = makeViewModel(localId: localId, remoteId: remoteId)

        viewModel.setMyReady()
        webSocket.onReadyStatusReceived?(remoteId)
        webSocket.onReadyStatusReceived?(remoteId)

        try await Task.sleep(for: .milliseconds(30))

        XCTAssertEqual(webSocket.sentInputs.count, 1)
        guard let payload = webSocket.sentInputs.first?.payload else {
            XCTFail("Expected websocket payload")
            return
        }
        let dto = try JSONDecoder().decode(NetworkGameStartSyncDTO.self, from: payload)
        let scheduled = viewModel.scheduledStartAt ?? 0
        XCTAssertLessThan(abs(scheduled - dto.startAt), 0.01)
    }

    func testReceivingStartAtSetsSchedule() async throws {
        let localId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let remoteId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let (viewModel, webSocket, _) = makeViewModel(localId: localId, remoteId: remoteId)

        viewModel.setMyReady()

        let startAt = Date().timeIntervalSince1970 + 1.5
        let payload = try JSONEncoder().encode(NetworkGameStartSyncDTO(startAt: startAt))
        webSocket.onInputReceived?(remoteId, payload)

        try await Task.sleep(for: .milliseconds(30))

        let scheduled = viewModel.scheduledStartAt ?? 0
        XCTAssertLessThan(abs(scheduled - startAt), 0.01)
    }

    func testHostSendsStartAtOverP2POnce() async throws {
        let localId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let remoteId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let (viewModel, _, networkSession) = makeViewModel(localId: localId, remoteId: remoteId, isNetwork: false)

        viewModel.setMyReady()
        networkSession.onReadyStatusReceived?(remoteId)
        networkSession.onReadyStatusReceived?(remoteId)

        try await Task.sleep(for: .milliseconds(30))

        XCTAssertEqual(networkSession.sentInputs.count, 1)
        guard let payload = networkSession.sentInputs.first?.payload else {
            XCTFail("Expected p2p payload")
            return
        }
        let dto = try JSONDecoder().decode(NetworkGameStartSyncDTO.self, from: payload)
        let scheduled = viewModel.scheduledStartAt ?? 0
        XCTAssertLessThan(abs(scheduled - dto.startAt), 0.01)
    }

    func testReceivingStartAtOverP2PSetsSchedule() async throws {
        let localId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let remoteId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let (viewModel, _, networkSession) = makeViewModel(localId: localId, remoteId: remoteId, isNetwork: false)

        viewModel.setMyReady()

        let startAt = Date().timeIntervalSince1970 + 1.5
        let payload = try JSONEncoder().encode(NetworkGameStartSyncDTO(startAt: startAt))
        networkSession.onInputReceived?(remoteId, payload)

        try await Task.sleep(for: .milliseconds(30))

        let scheduled = viewModel.scheduledStartAt ?? 0
        XCTAssertLessThan(abs(scheduled - startAt), 0.01)
    }
    
    private func makeViewModel(
        localId: UUID,
        remoteId: UUID,
        isNetwork: Bool = true
    ) -> (GameReadyViewModel, GameReadyMockWebSocketSessionManager, GameReadyMockNetworkSessionManager) {
        let local = PlayerInfo(id: localId, role: .local, displayName: "me", avatar: .character1)
        let remote = PlayerInfo(id: remoteId, role: .remote, displayName: "you", avatar: .character2)
        let connectivityMonitor = GameReadyMockConnectivityMonitor(isConnected: true)
        let networkSessionManager = GameReadyMockNetworkSessionManager()
        let webSocketSessionManager = GameReadyMockWebSocketSessionManager()
        let appEntryManager = AppEntryManager(permissionService: GameReadyMockPermissionService())

        let viewModel = GameReadyViewModel(
            localPlayer: local,
            remotePlayer: remote,
            isNetwork: isNetwork,
            connectivityMonitor: connectivityMonitor,
            networkSessionManager: networkSessionManager,
            webSocketSessionManager: webSocketSessionManager,
            appEntryManager: appEntryManager
        )

        return (viewModel, webSocketSessionManager, networkSessionManager)
    }
}
