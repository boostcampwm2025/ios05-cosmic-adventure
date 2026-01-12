import Vapor

actor WSSessionManager {
    static let shared = WSSessionManager()

    private var sessions: [String: WSSession] = [:]
    private var handlers: [any WSMessageHandler] = []

    private init() {}

    func register(_ handler: any WSMessageHandler) {
        handlers.append(handler)
    }

    func addSession(_ session: WSSession) {
        sessions[session.id] = session
    }

    func removeSession(_ sessionId: String) {
        sessions.removeValue(forKey: sessionId)
    }

    func getSession(_ sessionId: String) -> WSSession? {
        sessions[sessionId]
    }

    func getAllSessions() -> [WSSession] {
        Array(sessions.values)
    }

    func getSessionsInChannel(_ channelId: String) -> [WSSession] {
        sessions.values.filter { $0.metadata["channelId"] == channelId }
    }

    func broadcastToChannel(_ channelId: String, message: WSMessage, exclude: String? = nil) async {
        guard let text = message.encode() else { return }

        for session in getSessionsInChannel(channelId) {
            if let excludeId = exclude, session.id == excludeId { continue }
            if !session.isClosed {
                await session.send(text)
            }
        }
    }

    func handleMessage(_ text: String, from sessionId: String) async {
        guard let session = sessions[sessionId],
              let message = WSMessage.decode(from: text) else {
            return
        }

        await withTaskGroup(of: Void.self) { group in
            for handler in handlers {
                group.addTask {
                    await handler.handle(message, from: session, manager: self)
                }
            }
        }
    }

    func send(to sessionId: String, message: WSMessage) async {
        guard let session = sessions[sessionId],
              let text = message.encode() else {
            return
        }
        await session.send(text)
    }

    func broadcast(_ message: WSMessage, exclude: String? = nil) async {
        guard let text = message.encode() else { return }

        let sessionsToSend = sessions.values.filter { session in
            if let excludeId = exclude, session.id == excludeId { return false }
            return !session.isClosed
        }

        await withTaskGroup(of: Void.self) { group in
            for session in sessionsToSend {
                group.addTask {
                    await session.send(text)
                }
            }
        }
    }
}
