import Vapor

final class GameMessageHandler: WSMessageHandler, @unchecked Sendable {
    func handle(_ message: WSMessage, from session: WSSession, manager: WSSessionManager) async {
        guard let type = GameMessageType(rawValue: message.type) else { return }

        switch type {
        case .ping:
            let pong = WSMessage(type: GameMessageType.pong.rawValue, senderId: "server")
            await manager.send(to: session.id, message: pong)
        case .pong:
            break
        }
    }
}
