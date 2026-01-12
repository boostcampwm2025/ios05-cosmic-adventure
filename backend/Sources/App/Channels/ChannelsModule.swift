import Vapor

struct ChannelsModule: AppModule {
    func registerRoutes(_ app: Application) async throws {
        try app.register(collection: ChannelsController())
    }
}
