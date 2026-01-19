import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    let dbPath = Environment.get("SQLITE_PATH") ?? "db.sqlite"
    app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)

    MigrationRegistry.registerAll(in: app)
    try await app.autoMigrate()

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
