import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    MigrationRegistry.registerAll(in: app)

    try await registerModules(app)
}

private func registerModules(_ app: Application) async throws {
    app.get("status") { _ async in
        "Cosmic Adventure Server OK"
    }

    let modules: [any AppModule] = [
        ChannelsModule(),
        WebSocketModule(),
        GameModule(),
    ]

    for module in modules {
        try await module.registerRoutes(app)
    }
}
