import Vapor

actor WSSessionManager {
    static let shared = WSSessionManager()

    private var sessions: [String: WSSession] = [:]
    private var handlers: [any WSMessageHandler] = []
    private var pingTimestamps: [String: Date] = [:]
    private var latencies: [String: Double] = [:]
    private var pingTask: Task<Void, Never>?

    private init() {
        Task {
            await startPingTimer()
        }
    }

    func getLatency(for sessionId: String) -> Double? {
        latencies[sessionId]
    }

    private func startPingTimer() {
        pingTask = Task {
            while !Task.isCancelled {
                await sendPings()
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            }
        }
    }

    private func sendPings() async {
        let currentSessions = Array(sessions.values)
        let pingMessage = WSMessage(type: "ping", senderId: "server")
        
        await withTaskGroup(of: Void.self) { group in
            for session in currentSessions {
                if session.isClosed { continue }
                
                group.addTask {
                    await self.recordPingTime(for: session.id)
                    await self.send(to: session.id, message: pingMessage)
                }
            }
        }
    }

    private func recordPingTime(for sessionId: String) {
        pingTimestamps[sessionId] = Date()
    }

    func handlePong(from sessionId: String) {
        guard let pingDate = pingTimestamps[sessionId] else { return }
        
        let latency = Date().timeIntervalSince(pingDate) * 1000.0
        latencies[sessionId] = latency
        pingTimestamps.removeValue(forKey: sessionId)
    }

    func register(_ handler: any WSMessageHandler) {
        handlers.append(handler)
    }

    func addSession(_ session: WSSession) {
        sessions[session.id] = session
    }

    func removeSession(_ sessionId: String) {
        sessions.removeValue(forKey: sessionId)
        latencies.removeValue(forKey: sessionId)
        pingTimestamps.removeValue(forKey: sessionId)
    }

    func getSession(_ sessionId: String) -> WSSession? {
        sessions[sessionId]
    }

    func getAllSessions() -> [WSSession] {
        Array(sessions.values)
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
