import Vapor

struct GameModule: AppModule {
    func registerRoutes(_ app: Application) async throws {
        await WSSessionManager.shared.register(GameMessageHandler())
    }
}
