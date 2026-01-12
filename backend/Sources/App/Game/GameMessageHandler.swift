import Vapor

final class GameMessageHandler: WSMessageHandler, @unchecked Sendable {
    func handle(_ message: WSMessage, from session: WSSession, manager: WSSessionManager) async {
        guard let type = GameMessageType(rawValue: message.type) else { return }

        switch type {
        case .channelJoin:
            await handleChannelJoin(session: session, manager: manager)

        case .channelLeave:
            await handleChannelLeave(session: session, manager: manager)

        case .channelPlayerList:
            await sendPlayerList(to: session, manager: manager)

        case .invite, .inviteAccept, .inviteDecline, .inviteCancel:
            await forwardToTarget(message: message, manager: manager)

        case .input:
            await forwardToTarget(message: message, manager: manager)

        case .ping:
            let pong = WSMessage(type: GameMessageType.pong.rawValue, senderId: "server")
            await manager.send(to: session.id, message: pong)

        case .playerJoined, .playerLeft, .pong:
            break
        }
    }

    private func handleChannelJoin(session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        _ = await ChannelManager.shared.join(channelId)

        let playerInfo = buildPlayerInfo(from: session)
        let joinedMessage = WSMessage(
            type: GameMessageType.playerJoined.rawValue,
            senderId: session.id,
            payload: playerInfo
        )
        await manager.broadcastToChannel(channelId, message: joinedMessage, exclude: session.id)

        await sendPlayerList(to: session, manager: manager)
    }

    private func handleChannelLeave(session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        await ChannelManager.shared.leave(channelId)

        let leftMessage = WSMessage(
            type: GameMessageType.playerLeft.rawValue,
            senderId: session.id
        )
        await manager.broadcastToChannel(channelId, message: leftMessage, exclude: session.id)
    }

    private func sendPlayerList(to session: WSSession, manager: WSSessionManager) async {
        guard let channelId = session.metadata["channelId"] else { return }

        let players = await manager.getSessionsInChannel(channelId)
        let playerInfos = players.map { buildPlayerInfo(from: $0) }
        let payload = playerInfos.joined(separator: "|")

        let listMessage = WSMessage(
            type: GameMessageType.channelPlayerList.rawValue,
            senderId: "server",
            payload: payload
        )
        await manager.send(to: session.id, message: listMessage)
    }

    private func forwardToTarget(message: WSMessage, manager: WSSessionManager) async {
        guard let targetId = message.payload else { return }
        await manager.send(to: targetId, message: message)
    }

    private func buildPlayerInfo(from session: WSSession) -> String {
        let nickname = session.metadata["nickname"] ?? "unknown"
        return "\(session.id):\(nickname)"
    }
}
