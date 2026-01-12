import Vapor

struct ChannelResponseDTO: Content {
    let id: String
    let name: String
    let currentPlayers: Int
    let maxPlayers: Int
    let status: String
}

extension Channel {
    func toResponseDTO(currentPlayers: Int) -> ChannelResponseDTO {
        ChannelResponseDTO(
            id: id,
            name: name,
            currentPlayers: currentPlayers,
            maxPlayers: maxPlayers,
            status: status.rawValue
        )
    }
}
