import Vapor

final class GameMessageHandler: WSMessageHandler, Sendable {
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

    private func handleChannelJoin(session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        _ = await ChannelManager.shared.join(channelId, session: session)

        let latency = await manager.getLatency(for: session.id)
        let playerInfo = buildPlayerInfo(from: session, latency: latency)
        let joinedMessage = WSMessage(
            type: GameMessageType.playerJoined.rawValue,
            senderId: session.id,
            payload: playerInfo
        )
        
        /// 채널에 있는 다른 플레이어에게 새로운 플레이어가 입장했음을 알림
        await ChannelManager.shared.broadcastToChannel(channelId, message: joinedMessage, exclude: session.id)

        await sendPlayerList(in: channelId, to: session, manager: manager)
    }

    private func handleChannelLeave(session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        await ChannelManager.shared.leave(channelId, sessionId: session.id)

        let leftMessage = WSMessage(
            type: GameMessageType.playerLeft.rawValue,
            senderId: session.id
        )
        
        /// 채널에 있는 다른 플레이어에게 새로운 플레이어가 퇴장했음을 알림
        await ChannelManager.shared.broadcastToChannel(channelId, message: leftMessage, exclude: session.id)
    }

    func sendPlayerList(in channelId: String, to toSession: WSSession? = nil, manager: WSSessionManager) async {
        let sessionsInChannel = await ChannelManager.shared.getSessionsInChannel(channelId)
        guard !sessionsInChannel.isEmpty else { return }

        let playerInfos = await withTaskGroup(of: String.self) { group in
            for session in sessionsInChannel {
                group.addTask {
                    let latency = await manager.getLatency(for: session.id)
                    return self.buildPlayerInfo(from: session, latency: latency)
                }
            }
            
            return await group.reduce(into: [String]()) { $0.append($1) }
        }

        let playersArray = "[" + playerInfos.joined(separator: ",") + "]"

        if let session = toSession {
            let payload = "{\"youSessionId\":\"\(session.id)\",\"players\":\(playersArray)}"
            let listMessage = WSMessage(
                type: GameMessageType.channelPlayerList.rawValue,
                senderId: "server",
                payload: payload
            )
            await manager.send(to: session.id, message: listMessage)
        } else {
            for session in sessionsInChannel {
                let payload = "{\"youSessionId\":\"\(session.id)\",\"players\":\(playersArray)}"
                let listMessage = WSMessage(
                    type: GameMessageType.channelPlayerList.rawValue,
                    senderId: "server",
                    payload: payload
                )
                await manager.send(to: session.id, message: listMessage)
            }
        }
    }

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
        guard let channelId = session.metadata["channelId"] else { return }

        guard let payload = message.payload,
              let data = payload.data(using: .utf8),
              let routed = try? JSONDecoder().decode(ForwardingPayload.self, from: data) else {
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

    private func buildPlayerInfo(from session: WSSession, latency: Double?) -> String {
        let nickname = session.metadata["nickname"] ?? "unknown"
        let character = session.metadata["character"] ?? ""
        let lat = latency ?? 200.0

        let dict: [String: Any] = [
            "sessionId": session.id,
            "nickname": nickname,
            "characterRawValue": character,
            "latency": lat
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else {
            return "{\"sessionId\":\"\(session.id)\",\"nickname\":\"\(nickname)\",\"characterRawValue\":\"\(character)\",\"latency\":\(lat)}"
        }
        return json
    }
}
