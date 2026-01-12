import Foundation

actor ChannelManager {
    static let shared = ChannelManager()

    private let minChannels = 3
    private let maxPlayersPerChannel = 10
    private let scaleUpThreshold: Double = 0.8

    private var channels: [String: Channel] = [:]

    private init() {
        for i in 1...minChannels {
            let id = "channel-\(i)"
            channels[id] = Channel(
                id: id,
                name: "은하수 \(i)",
                currentPlayers: 0,
                maxPlayers: maxPlayersPerChannel,
                status: .available
            )
        }
    }

    func getChannels() -> [Channel] {
        channels.values.sorted { $0.id < $1.id }
    }

    func getChannel(_ id: String) -> Channel? {
        channels[id]
    }

    func join(_ channelId: String) async -> Bool {
        guard var channel = channels[channelId],
              !channel.isFull else {
            return false
        }

        channel.currentPlayers += 1
        if channel.isFull {
            channel.status = .full
        }
        channels[channelId] = channel

        await checkAndScaleUp()
        return true
    }

    func leave(_ channelId: String) async {
        guard var channel = channels[channelId] else { return }

        channel.currentPlayers = max(0, channel.currentPlayers - 1)
        if channel.status == .full {
            channel.status = .available
        }
        channels[channelId] = channel

        await checkAndScaleDown()
    }

    private func checkAndScaleUp() async {
        let totalCapacity = channels.count * maxPlayersPerChannel
        let totalPlayers = channels.values.reduce(0) { $0 + $1.currentPlayers }
        let occupancyRate = Double(totalPlayers) / Double(totalCapacity)

        if occupancyRate >= scaleUpThreshold {
            let newId = "channel-\(channels.count + 1)"
            channels[newId] = Channel(
                id: newId,
                name: "은하수 \(channels.count + 1)",
                currentPlayers: 0,
                maxPlayers: maxPlayersPerChannel,
                status: .available
            )
        }
    }

    private func checkAndScaleDown() async {
        guard channels.count > minChannels else { return }

        let emptyChannelIds = channels
            .filter { $0.value.currentPlayers == 0 }
            .map { $0.key }
            .sorted()
            .reversed()

        for id in emptyChannelIds {
            if channels.count > minChannels {
                channels.removeValue(forKey: id)
            }
        }
    }
}
