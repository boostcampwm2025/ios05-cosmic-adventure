//
//  LobbyViewModelChannelGatingTests.swift
//  App
//
//  Created by 영빈 on 2/4/26.
//

import Testing
import Foundation
@testable import App
import NetworkKit
import StorageKit

@MainActor
@Suite("LobbyViewModel 채널 리스트 게이팅")
struct LobbyViewModelChannelGatingTests {

    // MARK: - Helpers

    private func makeSUT() -> (
        sut: LobbyViewModel,
        mockP2P: MockNetworkSessionManager,
        mockWS: MockWebSocketSessionManager,
        mockConn: MockConnectivityMonitor
    ) {
        let mockP2P = MockNetworkSessionManager()
        let mockWS = MockWebSocketSessionManager()
        let mockConn = MockConnectivityMonitor()
        let mockPermission = MockPermissionService()
        let appEntry = AppEntryManager(permissionService: mockPermission)
        let coordinator = NetworkExplorationCoordinator(
            networkSessionManager: mockP2P,
            webSocketSessionManager: mockWS
        )
        let player = Player(id: UUID(), nickname: "TestPlayer", character: "character1")
        let sut = LobbyViewModel(
            explorationCoordinator: coordinator,
            connectivityMonitor: mockConn,
            networkSessionManager: mockP2P,
            webSocketSessionManager: mockWS,
            appEntryManager: appEntry,
            player: player
        )
        return (sut, mockP2P, mockWS, mockConn)
    }

    private func makeRemotePlayer(id: UUID = UUID()) -> PlayerInfo {
        PlayerInfo(id: id, role: .remote, displayName: "RemotePlayer", avatar: .character2)
    }

    private func enterChannelList(_ sut: LobbyViewModel, mockConn: MockConnectivityMonitor) async {
        sut.setup()
        mockConn.simulateConnectivityChange(isConnected: true)
        await Task.yield()
    }

    // MARK: - Tests

    @Test("채널 리스트 화면일 때, setupExploration 호출하면, P2P·WS 양쪽 모두 비활성화된다")
    func setupExploration_onChannelList_deactivatesBothStacks() async {
        // Given: 채널 리스트 화면 진입
        let (sut, mockP2P, mockWS, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)
        mockP2P.deactivateCallCount = 0
        mockWS.deactivateCallCount = 0

        // When: setupExploration 호출
        sut.setupExploration()

        // Then: P2P·WS 양쪽 모두 비활성화
        #expect(mockP2P.deactivateCallCount > 0)
        #expect(mockWS.deactivateCallCount > 0)
    }

    @Test("초대 요청 중일 때, 채널 리스트에 진입하면, 매치 상태가 idle로 초기화된다")
    func enterChannelList_cancelsOutboundSendingRequest() async {
        // Given: 초대 요청(sendingRequest) 중인 상태
        let (sut, _, _, mockConn) = makeSUT()
        sut.setup()
        let player = makeRemotePlayer()
        sut.remotePlayers = [player]
        sut.matchStatus = .sendingRequest(player: player)

        // When: 채널 리스트에 진입
        mockConn.simulateConnectivityChange(isConnected: true)
        await Task.yield()

        // Then: 매치 상태가 idle로 초기화
        #expect(sut.matchStatus == .idle)
    }

    @Test("초대를 수신한 상태일 때, 채널 리스트에 진입하면, 초대가 거절되고 알림·상태가 모두 초기화된다")
    func enterChannelList_declinesReceivedInviteAndResetsState() async {
        // Given: 초대를 수신한 상태 + 알림 표시 중
        let (sut, _, _, mockConn) = makeSUT()
        sut.setup()
        let player = makeRemotePlayer()
        sut.remotePlayers = [player]
        sut.matchStatus = .receivedInvite(player: player, wasSoloGame: false)
        sut.inviteNotifications = [InviteNotification(sender: player)]
        sut.isShowingNotification = true

        // When: 채널 리스트에 진입
        mockConn.simulateConnectivityChange(isConnected: true)
        await Task.yield()

        // Then: 초대 거절되고 알림·상태 모두 초기화
        #expect(sut.matchStatus == .idle)
        #expect(sut.inviteNotifications.isEmpty)
        #expect(sut.isShowingNotification == false)
    }

    @Test("채널 리스트 화면일 때, 초대 수신 이벤트가 발생하면, 무시되고 상태가 변하지 않는다")
    func handleInviteReceived_onChannelList_doesNothing() async {
        // Given: 채널 리스트 화면 + 원격 플레이어 존재
        let (sut, _, _, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)
        let player = makeRemotePlayer()
        sut.remotePlayers = [player]

        // When: 초대 수신 이벤트 발생
        sut.handleInviteReceived(from: player.id)

        // Then: 무시되고 상태 변화 없음
        #expect(sut.matchStatus == .idle)
        #expect(sut.inviteNotifications.isEmpty)
    }

    @Test("채널 리스트 화면일 때, 초대 수락 이벤트가 발생하면, 무시되고 상태가 변하지 않는다")
    func handleInviteAccepted_onChannelList_doesNothing() async {
        // Given: 채널 리스트 화면
        let (sut, _, _, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)

        // When: 초대 수락 이벤트 발생
        let someId = UUID()
        sut.handleInviteAccepted(from: someId)

        // Then: 무시되고 상태 변화 없음
        #expect(sut.matchStatus == .idle)
    }

    @Test("채널 리스트 화면일 때, 초대 거절 이벤트가 발생하면, 무시되고 상태가 변하지 않는다")
    func handleInviteDeclined_onChannelList_doesNothing() async {
        // Given: 채널 리스트 화면
        let (sut, _, _, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)

        // When: 초대 거절 이벤트 발생
        let someId = UUID()
        sut.handleInviteDeclined(from: someId)

        // Then: 무시되고 상태 변화 없음
        #expect(sut.matchStatus == .idle)
    }

    @Test("채널 리스트 화면일 때, 초대 취소 이벤트가 발생하면, 무시되고 상태가 변하지 않는다")
    func handleInviteCancelled_onChannelList_doesNothing() async {
        // Given: 채널 리스트 화면
        let (sut, _, _, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)

        // When: 초대 취소 이벤트 발생
        let someId = UUID()
        sut.handleInviteCancelled(from: someId)

        // Then: 무시되고 상태 변화 없음
        #expect(sut.matchStatus == .idle)
    }

    @Test("채널 리스트 화면일 때, 알림에서 초대 수락하면, 무시되고 상태가 변하지 않는다")
    func acceptInviteFromNotification_onChannelList_doesNothing() async {
        // Given: 채널 리스트 화면
        let (sut, _, _, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)

        // When: 알림에서 초대 수락
        let player = makeRemotePlayer()
        let notification = InviteNotification(sender: player)
        sut.acceptInviteFromNotification(notification)

        // Then: 무시되고 상태 변화 없음
        #expect(sut.matchStatus == .idle)
    }

    @Test("채널 리스트 화면일 때, 알림에서 초대 거절하면, 무시되고 상태가 변하지 않는다")
    func declineInviteFromNotification_onChannelList_doesNothing() async {
        // Given: 채널 리스트 화면
        let (sut, _, _, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)

        // When: 알림에서 초대 거절
        let player = makeRemotePlayer()
        let notification = InviteNotification(sender: player)
        sut.declineInviteFromNotification(notification)

        // Then: 무시되고 상태 변화 없음
        #expect(sut.matchStatus == .idle)
    }

    @Test("채널 리스트 화면일 때, 네트워크 연결이 반복 발생하면, 탐색이 재활성화되지 않는다")
    func repeatedConnectivityOnline_doesNotActivateExploration() async {
        // Given: 채널 리스트 화면 + activate 카운터 리셋
        let (sut, mockP2P, mockWS, mockConn) = makeSUT()
        await enterChannelList(sut, mockConn: mockConn)
        mockP2P.activateCalls = []
        mockWS.activateCalls = []

        // When: 네트워크 연결 재발생
        mockConn.simulateConnectivityChange(isConnected: true)
        await Task.yield()

        // Then: 탐색이 재활성화되지 않음
        #expect(mockP2P.activateCalls.isEmpty)
        #expect(mockWS.activateCalls.isEmpty)
    }

    @Test("알림 팝오버가 표시 중일 때, 채널 리스트로 전환하면, 팝오버가 닫힌다")
    func channelListTransition_closesNotificationPopover() async {
        // Given: 알림 팝오버 표시 중
        let (sut, _, _, mockConn) = makeSUT()
        sut.setup()
        sut.isShowingNotification = true

        // When: 채널 리스트로 전환
        mockConn.simulateConnectivityChange(isConnected: true)
        await Task.yield()

        // Then: 팝오버가 닫힘
        #expect(sut.isShowingNotification == false)
    }

    @Test("매치 상태가 있을 때, cleanup을 두 번 연속 호출하면, 크래시 없이 정상 동작한다")
    func cleanup_isIdempotent() async {
        // Given: 초대 요청 중인 상태
        let (sut, _, _, mockConn) = makeSUT()
        sut.setup()
        let player = makeRemotePlayer()
        sut.remotePlayers = [player]
        sut.matchStatus = .sendingRequest(player: player)

        // When: 첫 번째 cleanup — 채널 리스트 전환
        mockConn.simulateConnectivityChange(isConnected: true)
        await Task.yield()

        // Then: idle로 초기화
        #expect(sut.matchStatus == .idle)

        // When: 두 번째 cleanup — selectChannel 후 leaveChannel
        sut.selectChannel("ch1")
        sut.leaveChannel()

        // Then: 크래시 없이 정상 동작
        #expect(sut.matchStatus == .idle)
        #expect(sut.isOnChannelList == true)
    }
}
