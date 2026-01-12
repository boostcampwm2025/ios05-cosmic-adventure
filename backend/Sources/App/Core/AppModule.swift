import Vapor

protocol AppModule {
    func registerRoutes(_ app: Application) async throws
}
