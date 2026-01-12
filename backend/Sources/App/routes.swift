import Vapor

func routes(_ app: Application) throws {
    app.get("status") { _ async in
        "Cosmic Adventure Server OK"
    }
}
