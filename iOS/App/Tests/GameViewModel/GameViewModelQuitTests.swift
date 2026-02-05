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
