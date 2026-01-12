import Vapor

struct ChannelsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let channels = routes.grouped("api", "v1", "channels")

        channels.get(use: index)
        channels.get(":id", use: show)
    }

    @Sendable
    func index(req: Request) async throws -> [ChannelResponseDTO] {
        await ChannelManager.shared.getAllChannelResponses()
    }

    @Sendable
    func show(req: Request) async throws -> ChannelResponseDTO {
        guard let id = req.parameters.get("id"),
              let response = await ChannelManager.shared.getChannelResponse(id) else {
            throw Abort(.notFound, reason: "Channel not found")
        }
        return response
    }
}
