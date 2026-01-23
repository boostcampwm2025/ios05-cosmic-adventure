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

    case readyToSend(peer: PlayerInfo)
    case sendingRequest(peer: PlayerInfo)
    case receivedInvite(peer: PlayerInfo, wasSoloGame: Bool = false)
    case requestDeclined(peer: PlayerInfo)
    case gameReady(peer: PlayerInfo)

    mutating func reset() {
        self = .idle
    }
    
    mutating func setSoloGame() {
        self = .soloGame
    }

    mutating func select(_ peer: PlayerInfo) {
        self = .readyToSend(peer: peer)
    }

    mutating func sendRequest() {
        if case .readyToSend(let peer) = self {
            self = .sendingRequest(peer: peer)
        }
    }

    mutating func requestDeclined(by peer: PlayerInfo) {
        self = .requestDeclined(peer: peer)
    }

    mutating func receiveInvite(from peer: PlayerInfo, wasSoloGame: Bool = false) {
        self = .receivedInvite(peer: peer, wasSoloGame: wasSoloGame)
    }

    mutating func setGameReady(with peer: PlayerInfo) {
        self = .gameReady(peer: peer)
    }
}
