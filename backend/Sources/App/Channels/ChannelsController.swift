import Vapor

struct ChannelsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let channels = routes.grouped("api", "v1", "channels")

        channels.get(use: index)
        channels.get(":id", use: show)
    }

    @Sendable
    func index(req: Request) async throws -> [ChannelResponseDTO] {
        let channels = await ChannelManager.shared.getChannels()
        var result: [ChannelResponseDTO] = []
        for channel in channels {
            let playerCount = await ChannelManager.shared.getPlayerCount(channel.id)
            result.append(channel.toResponseDTO(currentPlayers: playerCount))
        }
        return result
    }

    @Sendable
    func show(req: Request) async throws -> ChannelResponseDTO {
        guard let id = req.parameters.get("id"),
              let channel = await ChannelManager.shared.getChannel(id) else {
            throw Abort(.notFound, reason: "Channel not found")
        }
        let playerCount = await ChannelManager.shared.getPlayerCount(id)
        return channel.toResponseDTO(currentPlayers: playerCount)
    }
}
