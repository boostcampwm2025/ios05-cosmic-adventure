import Foundation

struct Channel: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    var currentPlayers: Int
    let maxPlayers: Int
    var status: ChannelStatus

    var isFull: Bool {
        currentPlayers >= maxPlayers
    }

    var occupancyRate: Double {
        Double(currentPlayers) / Double(maxPlayers)
    }
}

enum ChannelStatus: String, Codable, Sendable {
    case available
    case full
    case maintenance
}
