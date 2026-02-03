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

    mutating func reset() {
        self = .idle
    }
    
    mutating func setSoloGame() {
        self = .soloGame
    }

    mutating func select(_ player: PlayerInfo) {
        self = .readyToSend(player: player)
    }

    mutating func sendRequest() {
        if case .readyToSend(let player) = self {
            self = .sendingRequest(player: player)
        }
    }

    mutating func requestDeclined(by player: PlayerInfo) {
        self = .requestDeclined(player: player)
    }

    mutating func receiveInvite(from player: PlayerInfo, wasSoloGame: Bool = false) {
        self = .receivedInvite(player: player, wasSoloGame: wasSoloGame)
    }

    mutating func setGameReady(with player: PlayerInfo) {
        self = .gameReady(player: player)
    }
}
