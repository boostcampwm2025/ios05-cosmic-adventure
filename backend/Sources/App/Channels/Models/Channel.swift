import Foundation

struct Channel: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let maxPlayers: Int
    var status: ChannelStatus

    func isFull(currentPlayers: Int) -> Bool {
        currentPlayers >= maxPlayers
    }

    func occupancyRate(currentPlayers: Int) -> Double {
        Double(currentPlayers) / Double(maxPlayers)
    }
}

enum ChannelStatus: String, Codable, Sendable {
    case available
    case full
    case maintenance
}
