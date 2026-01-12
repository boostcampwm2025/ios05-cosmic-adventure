import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    MigrationRegistry.registerAll(in: app)

    try registerModules(app)
}

private func registerModules(_ app: Application) throws {
    app.get("status") { _ async in
        "Cosmic Adventure Server OK"
    }

    let modules: [any AppModule] = [
        ChannelsModule(),
    ]

    for module in modules {
        try module.registerRoutes(app)
    }
}
