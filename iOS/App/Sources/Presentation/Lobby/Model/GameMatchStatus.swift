//
//  LobbyConnectionStatus.swift
//  App
//
//  Created by soyoung on 1/12/26.
//

import Foundation

enum GameMatchStatus: Equatable {
    case idle
    case soloGame

    case readyToSend(player: PlayerInfo)
    case sendingRequest(player: PlayerInfo)
    case receivedInvite(player: PlayerInfo, wasSoloGame: Bool = false)
    case requestDeclined(player: PlayerInfo)
    case gameReady(player: PlayerInfo)

    mutating func handle(_ event: MatchEvent) {
        switch (self, event) {
        case (_, .reset):
            self = .idle

        case (.idle, .startSoloGame):
            self = .soloGame

        case (.idle, .selectPlayer(let player)),
             (.requestDeclined, .selectPlayer(let player)):
            self = .readyToSend(player: player)

        case (_, .deselectPlayer):
            self = .idle

        case (.readyToSend(let player), .sendInvite):
            self = .sendingRequest(player: player)

        case (.sendingRequest, .cancelOutboundInvite):
            self = .idle

        case (.sendingRequest, .inviteAccepted(let player)):
            self = .gameReady(player: player)

        case (.sendingRequest, .inviteDeclined(let player)):
            self = .requestDeclined(player: player)

        case (.idle, .receiveInvite(let player, let wasSoloGame)),
             (.soloGame, .receiveInvite(let player, let wasSoloGame)),
             (.requestDeclined, .receiveInvite(let player, let wasSoloGame)):
            self = .receivedInvite(player: player, wasSoloGame: wasSoloGame)

        case (.receivedInvite(let player, _), .acceptInvite):
            self = .gameReady(player: player)

        case (.receivedInvite(_, let wasSoloGame), .declineInvite):
            self = wasSoloGame ? .soloGame : .idle

        case (.receivedInvite(_, let wasSoloGame), .inviteCancelled):
            self = wasSoloGame ? .soloGame : .idle

        default:
            break
        }
    }
}
