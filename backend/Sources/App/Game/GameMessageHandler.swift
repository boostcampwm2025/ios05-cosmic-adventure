import Vapor

final class GameMessageHandler: WSMessageHandler, Sendable {
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func handle(_ message: WSMessage, from session: WSSession, manager: WSSessionManager) async {
        guard let type = GameMessageType(rawValue: message.type) else { return }

        switch type {
        case .channelJoin:
            await handleChannelJoin(session: session, manager: manager)

        case .channelLeave:
            await handleChannelLeave(session: session, manager: manager)

        case .channelPlayerList:
            if let channelId = session.metadata["channelId"] {
                await sendPlayerList(in: channelId, to: session, manager: manager)
            }

        case .invite, .inviteAccept, .inviteDecline, .inviteCancel, .gameReady:
            await forwardToTarget(message: message, from: session, manager: manager)

        case .input, .videoFrame, .gameEnded:
            await handleForwarding(message: message, from: session, manager: manager)

        case .ping:
            let pong = WSMessage(type: GameMessageType.pong.rawValue, senderId: "server")
            await manager.send(to: session.id, message: pong)

        case .pong:
            await manager.handlePong(from: session.id)

        case .playerJoined, .playerLeft:
            break
        }
    }

    // MARK: - Core Handlers

    func handleChannelJoin(session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        _ = await ChannelManager.shared.join(channelId, session: session)

        let playerInfo = await getPlayerInfo(from: session, manager: manager)
        if let payload = try? encoder.encodeAsString(playerInfo) {
            let joinedMessage = WSMessage(
                type: GameMessageType.playerJoined.rawValue,
                senderId: session.id,
                payload: payload
            )
            await ChannelManager.shared.broadcastToChannel(channelId, message: joinedMessage, exclude: session.id)
        }

        await sendPlayerList(in: channelId, to: session, manager: manager)
    }

    private func handleChannelLeave(session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        await ChannelManager.shared.leave(channelId, sessionId: session.id)

        let leftMessage = WSMessage(
            type: GameMessageType.playerLeft.rawValue,
            senderId: session.id
        )
        await ChannelManager.shared.broadcastToChannel(channelId, message: leftMessage, exclude: session.id)
    }

    func sendPlayerList(in channelId: String, to toSession: WSSession? = nil, manager: WSSessionManager) async {
        let sessionsInChannel = await ChannelManager.shared.getSessionsInChannel(channelId)
        guard !sessionsInChannel.isEmpty else { return }

        var allPlayers: [PlayerInfo] = []
        for session in sessionsInChannel {
            allPlayers.append(await getPlayerInfo(from: session, manager: manager))
        }

        let sessionsToSend = toSession.map { [$0] } ?? sessionsInChannel

        for session in sessionsToSend {
            let payloadObj = PlayerListPayload(youSessionId: session.id, players: allPlayers)

            if let payloadString = try? encoder.encodeAsString(payloadObj) {
                let listMessage = WSMessage(
                    type: GameMessageType.channelPlayerList.rawValue,
                    senderId: "server",
                    payload: payloadString
                )
                await manager.send(to: session.id, message: listMessage)
            }
        }
    }

    // MARK: - Forwarding

    private func forwardToTarget(message: WSMessage, from session: WSSession, manager: WSSessionManager) async {
        guard let targetId = message.payload else { return }
        let forwarded = WSMessage(
            type: message.type,
            senderId: session.id,
            payload: message.payload
        )
        await manager.send(to: targetId, message: forwarded)
    }

    private func handleForwarding(message: WSMessage, from session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"],
              let payloadData = message.payload?.data(using: .utf8),
              let routed = try? decoder.decode(ForwardingPayload.self, from: payloadData) else {
            return
        }

        let sessions = await ChannelManager.shared.getSessionsInChannel(channelId)
        guard sessions.contains(where: { $0.id == routed.to }) else { return }

        let forwarded = WSMessage(
            type: message.type,
            senderId: session.id,
            payload: routed.data
        )
        await manager.send(to: routed.to, message: forwarded)
    }

    // MARK: - Helpers

    /// 세션 메타데이터와 Latency를 기반으로 PlayerInfo 객체 생성.
    private func getPlayerInfo(from session: WSSession, manager: WSSessionManager) async -> PlayerInfo {
        let latency = await manager.getLatency(for: session.id)
        return PlayerInfo(
            sessionId: session.id,
            nickname: session.metadata["nickname"] ?? "unknown",
            characterRawValue: session.metadata["character"] ?? "",
            latency: latency ?? 200.0
        )
    }
}

// MARK: - JSONEncoder Extension

extension JSONEncoder {
    func encodeAsString<T: Encodable>(_ value: T) throws -> String {
        let data = try self.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(value, .init(codingPath: [], debugDescription: "Failed to convert encoded data to UTF-8 string"))
        }
        return string
    }
}
