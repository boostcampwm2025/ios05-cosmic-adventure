import XCTest
@testable import App
import Games
import NetworkKit

@MainActor
final class GameViewModelRespawnTests: XCTestCase {
    func testRequestRespawnSetsRespawningState() async {
        let viewModel = makeViewModel()

        viewModel.requestRespawn()

        XCTAssertTrue(viewModel.gameplayManager.isPlayerRespawning(for: viewModel.localPlayerID))
    }

    func testRequestRespawnIsIgnoredAfterGameEnd() async {
        let viewModel = makeViewModel()

        viewModel.gameplayManager.applyGameEnd(.quit)
        viewModel.requestRespawn()

        XCTAssertFalse(viewModel.gameplayManager.isPlayerRespawning(for: viewModel.localPlayerID))
    }

    func testRequestRespawnDoesNotToggleOffWhenCalledTwice() async {
        let viewModel = makeViewModel()

        viewModel.requestRespawn()
        viewModel.requestRespawn()

        XCTAssertTrue(viewModel.gameplayManager.isPlayerRespawning(for: viewModel.localPlayerID))
    }
}

private extension GameViewModelRespawnTests {
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
}
