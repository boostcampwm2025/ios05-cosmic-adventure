import XCTest
@testable import App
import Games
import NetworkKit

@MainActor
final class GameViewModelQuitTests: XCTestCase {
    func testUpdateLocalGameEndDisplayQuitSetsQuitFields() async {
        let viewModel = makeViewModel()

        viewModel.updateLocalGameEndDisplay(.quit)

        XCTAssertEqual(viewModel.gameEndDisplay?.reason, .quit)
        XCTAssertNil(viewModel.gameEndDisplay?.winnerId)
        XCTAssertNil(viewModel.gameEndDisplay?.winnerName)
        XCTAssertNil(viewModel.gameEndDisplay?.opponentName)
    }

    func testGameEndReasonTextForQuit() async {
        let viewModel = makeViewModel()

        viewModel.updateLocalGameEndDisplay(.quit)

        XCTAssertEqual(viewModel.gameEndReasonText, L10N.Game.End.quitTitle)
    }

    func testQuitHidesWinnerAndOpponentTexts() async {
        let viewModel = makeViewModel()

        viewModel.updateLocalGameEndDisplay(.quit)

        XCTAssertNil(viewModel.gameEndWinnerText)
        XCTAssertNil(viewModel.gameEndOpponentText)
        XCTAssertNil(viewModel.gameEndOpponentElapsedText)
    }

    func testApplyRemoteGameEndQuitSetsDisplay() async {
        let viewModel = makeViewModel()
        let dto = NetworkGameEndDTO(reason: .quit)

        viewModel.applyRemoteGameEnd(dto)

        XCTAssertEqual(viewModel.gameEndDisplay?.reason, .quit)
        XCTAssertNil(viewModel.gameEndDisplay?.winnerId)
        XCTAssertNil(viewModel.gameEndDisplay?.winnerName)
        XCTAssertNil(viewModel.gameEndDisplay?.opponentName)
    }

    func testNotifyGameEndedQuitSendsToNetworkLayer() async {
        let local = PlayerInfo(role: .local, displayName: "Local", avatar: .character1)
        let remote = PlayerInfo(role: .remote, displayName: "Remote", avatar: .character2)
        let config = MockGameConfig()
        let connection = MockConnectionSessionManager()
        let multiplayer = MockMultiplayerIO()
        let endCondition = TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 10)
        let viewModel = GameViewModel(
            localPlayer: local,
            remotePlayer: remote,
            endCondition: endCondition,
            connectionSessionManager: connection,
            gameConfig: config,
            multiplayerIO: multiplayer
        )

        viewModel.notifyGameEnded(.quit)

        XCTAssertEqual(multiplayer.notifiedReasons.last, .quit)
    }

    func testReceiveRemoteQuitUpdatesDisplay() async {
        let local = PlayerInfo(role: .local, displayName: "Local", avatar: .character1)
        let remote = PlayerInfo(role: .remote, displayName: "Remote", avatar: .character2)
        let config = MockGameConfig()
        let connection = MockConnectionSessionManager()
        let multiplayer = MockMultiplayerIO()
        let endCondition = TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 10)
        let viewModel = GameViewModel(
            localPlayer: local,
            remotePlayer: remote,
            endCondition: endCondition,
            connectionSessionManager: connection,
            gameConfig: config,
            multiplayerIO: multiplayer
        )

        let dto = NetworkGameEndDTO(reason: .quit)
        multiplayer.onGameEndReceivedHandler?(dto)
        await waitForRemoteDisplayUpdate(viewModel)

        XCTAssertEqual(viewModel.gameEndDisplay?.reason, .quit)
        XCTAssertNil(viewModel.gameEndDisplay?.winnerId)
    }

    func testRemoteReceiveHandlerIsInstalledForMultiplayer() async {
        let local = PlayerInfo(role: .local, displayName: "Local", avatar: .character1)
        let remote = PlayerInfo(role: .remote, displayName: "Remote", avatar: .character2)
        let config = MockGameConfig()
        let connection = MockConnectionSessionManager()
        let multiplayer = MockMultiplayerIO()
        let endCondition = TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 10)
        _ = GameViewModel(
            localPlayer: local,
            remotePlayer: remote,
            endCondition: endCondition,
            connectionSessionManager: connection,
            gameConfig: config,
            multiplayerIO: multiplayer
        )

        XCTAssertNotNil(multiplayer.onGameEndReceivedHandler)
    }
}

private extension GameViewModelQuitTests {
    func makeViewModel() -> GameViewModel {
        let local = PlayerInfo(role: .local, displayName: "Local", avatar: .character1)
        let config = MockGameConfig()
        let connection = MockConnectionSessionManager()
        let endCondition = TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 10)
        let multiplayer = MockMultiplayerIO()
        return GameViewModel(
            localPlayer: local,
            remotePlayer: nil,
            endCondition: endCondition,
            connectionSessionManager: connection,
            gameConfig: config,
            multiplayerIO: multiplayer
        )
    }

    func waitForRemoteDisplayUpdate(_ viewModel: GameViewModel) async {
        for _ in 0..<20 {
            if viewModel.gameEndDisplay != nil { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("Timed out waiting for remote display update.")
    }
}

private struct MockGameConfig: GameConfigProviding {
    let jumpSensitivity: SettingsLevel = .medium
    let tiltSensitivity: SettingsLevel = .medium
    let facePreviewSize: SettingsLevel = .medium
}

private final class MockConnectionSessionManager: ConnectionSessionManaging {
    var onInviteReceived: ((UUID) -> Void)?
    var onInviteAccepted: ((UUID) -> Void)?
    var onInviteDeclined: ((UUID) -> Void)?
    var onInviteCancelled: ((UUID) -> Void)?
    var onInputReceived: ((UUID, Data) -> Void)?
    var onReadyStatusReceived: ((UUID) -> Void)?
    var onVideoReceived: ((UUID, Data) -> Void)?
    var onGameEnded: ((UUID, NetworkGameEndDTO) -> Void)?

    func activate(channelId: String?, nickname: String) {}
    func deactivate() {}
    func sendInvite(to targetId: UUID) {}
    func acceptInvite(from targetId: UUID) {}
    func declineInvite(from targetId: UUID) {}
    func cancelInvite(to targetId: UUID) {}
    func sendInput<T: Codable>(_ data: T, to targetId: UUID?) {}
    func sendReadyStatus(to targetId: UUID) {}
    func sendVideo(_ data: Data, to targetId: UUID?) {}
    func getLatency(for playerId: UUID) -> Double? { nil }
    func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: UUID?) {}
}

private final class MockMultiplayerIO: MultiplayerNetworkManaging {
    var boundPeerId: UUID?
    var notifiedReasons: [GameEndReason] = []
    var onGameEndReceivedHandler: (@Sendable (NetworkGameEndDTO) -> Void)?
    var didTick: [TimeInterval] = []

    func bind(peerId: UUID) {
        boundPeerId = peerId
    }

    func unbind() {}

    func notifyGameEnded(_ reason: GameEndReason) {
        notifiedReasons.append(reason)
    }

    func setOnGameEndReceived(_ handler: @escaping @Sendable (NetworkGameEndDTO) -> Void) {
        onGameEndReceivedHandler = handler
    }

    func tick(deltaTime: TimeInterval) {
        didTick.append(deltaTime)
    }
}
