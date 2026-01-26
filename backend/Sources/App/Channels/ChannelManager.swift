import Vapor

actor ChannelManager {
    static let shared = ChannelManager()

    private let minChannels = 3
    private let maxPlayersPerChannel = 10
    private let scaleUpThreshold: Double = 0.8
    private let cleanupInterval: TimeInterval = 15.0

    /// 채널 메타데이터 (REST API 응답용: id, name, maxPlayers, status)
    private var channels: [String: Channel] = [:]
    /// 채널별 WebSocket 세션 (실시간 메시지 브로드캐스트용) - [channelId: [sessionId: WSSession]]
    private var channelSessions: [String: [String: WSSession]] = [:]
    private var cleanupTask: Task<Void, Never>?

    private init() {
        for i in 1...minChannels {
            let id = "channel-\(i)"
            channels[id] = Channel(
                id: id,
                name: "은하수 \(i)",
                maxPlayers: maxPlayersPerChannel,
                status: .available
            )
            channelSessions[id] = [:]
        }
        Task {
            await startCleanupTimer()
        }
    }

    func getChannels() -> [Channel] {
        channels.values.sorted { $0.id < $1.id }
    }

    func getChannel(_ id: String) -> Channel? {
        channels[id]
    }

    func getPlayerCount(_ channelId: String) -> Int {
        channelSessions[channelId]?.count ?? 0
    }

    func getAllChannelResponses() -> [ChannelResponseDTO] {
        channels.values
            .sorted { $0.id < $1.id }
            .map { channel in
                let playerCount = channelSessions[channel.id]?.count ?? 0
                return channel.toResponseDTO(currentPlayers: playerCount)
            }
    }

    func getChannelResponse(_ id: String) -> ChannelResponseDTO? {
        guard let channel = channels[id] else { return nil }
        let playerCount = channelSessions[id]?.count ?? 0
        return channel.toResponseDTO(currentPlayers: playerCount)
    }

    func join(_ channelId: String, session: WSSession) async -> Bool {
        guard var channel = channels[channelId] else { return false }

        let currentPlayers = getPlayerCount(channelId)
        if channel.isFull(currentPlayers: currentPlayers) { return false }

        channelSessions[channelId]?[session.id] = session

        if channel.isFull(currentPlayers: currentPlayers + 1) {
            channel.status = .full
            channels[channelId] = channel
        }

        checkAndScaleUp()
        return true
    }

    func leave(_ channelId: String, sessionId: String) async {
        guard var channel = channels[channelId] else { return }

        channelSessions[channelId]?.removeValue(forKey: sessionId)

        if channel.status == .full {
            channel.status = .available
            channels[channelId] = channel
        }

        checkAndScaleDown()
    }

    func getSessionsInChannel(_ channelId: String) -> [WSSession] {
        guard let sessions = channelSessions[channelId] else { return [] }
        return Array(sessions.values)
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

    private func checkAndScaleUp() {
        let totalCapacity = channels.count * maxPlayersPerChannel
        let totalPlayers = channelSessions.values.reduce(0) { $0 + $1.count }
        let occupancyRate = Double(totalPlayers) / Double(totalCapacity)

        if occupancyRate >= scaleUpThreshold {
            let newId = "channel-\(channels.count + 1)"
            channels[newId] = Channel(
                id: newId,
                name: "은하수 \(channels.count + 1)",
                maxPlayers: maxPlayersPerChannel,
                status: .available
            )
            channelSessions[newId] = [:]
        }
    }

    private func checkAndScaleDown() {
        guard channels.count > minChannels else { return }

        let emptyChannelIds = channelSessions
            .filter { $0.value.isEmpty }
            .map { $0.key }
            .sorted()
            .reversed()

        for id in emptyChannelIds {
            if channels.count > minChannels {
                channels.removeValue(forKey: id)
                channelSessions.removeValue(forKey: id)
            }
        }
    }

    // MARK: - Ghost Session Cleanup

    private func startCleanupTimer() {
        cleanupTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(cleanupInterval))
                await cleanupGhostSessions()
            }
        }
    }

    private func cleanupGhostSessions() async {
        var ghostSessionIds: [(channelId: String, sessionId: String)] = []

        for (channelId, sessions) in channelSessions {
            for (sessionId, session) in sessions {
                if session.isClosed {
                    ghostSessionIds.append((channelId, sessionId))
                }
            }
            
            await Task.yield()
        }
        
        if ghostSessionIds.isEmpty { return }

        await withTaskGroup { group in
            for ghost in ghostSessionIds {
                group.addTask {
                    await self.removeGhostSession(channelId: ghost.channelId, sessionId: ghost.sessionId)
                    
                    // TODO: channelLeave인지 playerLeft인지 확인 필요
                    let leftMessage = WSMessage(
                        type: GameMessageType.playerLeft.rawValue,
                        senderId: ghost.sessionId)
                    
                    await self.broadcastToChannel(ghost.channelId, message: leftMessage, exclude: ghost.sessionId)
                    
                }
            }
        }
        
        checkAndScaleDown()
    }
    
    private func removeGhostSession(channelId: String, sessionId: String) async {
        print("[ChannelManager] 채널-\(channelId)의 ghost session 제거\(sessionId)")
        channelSessions[channelId]?.removeValue(forKey: sessionId)
    }
}
