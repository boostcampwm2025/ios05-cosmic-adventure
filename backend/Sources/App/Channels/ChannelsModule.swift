import Vapor

struct ChannelsModule: AppModule {
    func registerRoutes(_ app: Application) throws {
        try app.register(collection: ChannelsController())
    }
}
