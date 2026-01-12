import Vapor

protocol WSMessageHandler: Sendable {
    func handle(_ message: WSMessage, from session: WSSession, manager: WSSessionManager) async
}
