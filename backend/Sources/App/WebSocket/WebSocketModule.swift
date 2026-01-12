import Vapor

struct WebSocketModule: AppModule {
    func registerRoutes(_ app: Application) async throws {
        try app.register(collection: WSController())
    }
}
