import Vapor

actor WSSessionManager {
    static let shared = WSSessionManager()

    private var sessions: [String: WSSession] = [:]
    private var handlers: [any WSMessageHandler] = []
    private var pingTimestamps: [String: Date] = [:]
    private var latencies: [String: Double] = [:]
    private var pingTask: Task<Void, Never>?

    private var lastPongTimes: [String: Date] = [:]      // sessionId → 마지막 pong 시간
    private let pongTimeout: TimeInterval = 7.0

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
                await checkTimeouts()
                try? await Task.sleep(for: .seconds(5))
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

    func handlePong(from sessionId: String) async {
        guard let pingDate = pingTimestamps[sessionId] else { return }

        let latency = Date().timeIntervalSince(pingDate) * 1000.0
        latencies[sessionId] = latency
        pingTimestamps.removeValue(forKey: sessionId)
        lastPongTimes[sessionId] = Date()

        // Latency가 갱신되었으니, 유저가 속한 채널에 최신 리스트 전파
        if let session = sessions[sessionId],
           let channelId = session.metadata["channelId"] {
            for handler in handlers {
                if let gameHandler = handler as? GameMessageHandler {
                    await gameHandler.sendPlayerList(in: channelId, manager: self)
                    break
                }
            }
        }
    }

    func register(_ handler: any WSMessageHandler) {
        handlers.append(handler)
    }

    func addSession(_ session: WSSession) {
        sessions[session.id] = session
        lastPongTimes[session.id] = Date()
    }

    func removeSession(_ sessionId: String) async {
        if let channelId = sessions[sessionId]?.metadata["channelId"] {
            await ChannelManager.shared.leave(channelId, sessionId: sessionId)
            
            let leftMessage = WSMessage(
                type: GameMessageType.playerLeft.rawValue,
                senderId: sessionId
            )
            
            /// 채널 내 다른 플레이어들에게 특정 플레이어의 퇴장을 알림
            await ChannelManager.shared.broadcastToChannel(channelId, message: leftMessage, exclude: sessionId)

            sessions.removeValue(forKey: sessionId)
            latencies.removeValue(forKey: sessionId)
            pingTimestamps.removeValue(forKey: sessionId)
            lastPongTimes.removeValue(forKey: sessionId)
        }
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

    // MARK: - Timeout Check

    private func checkTimeouts() async {
        let now = Date()
        var timedOutSessionIds: [String] = []

        for (sessionId, lastPong) in lastPongTimes {
            if now.timeIntervalSince(lastPong) > pongTimeout {
                timedOutSessionIds.append(sessionId)
            }
        }

        for sessionId in timedOutSessionIds {
            print("[WSSessionManager] 세션 \(sessionId) 타임아웃 (\(pongTimeout)s 동안 응답없음)")
            await removeSession(sessionId)
        }
    }
}
