//
//  LobbyConnectionStatus.swift
//  App
//
//  Created by soyoung on 1/12/26.
//

import Foundation

enum GameMatchStatus: Equatable {
    case idle
    case readyToSend(peer: PlayerInfo)
    case sendingRequest(peer: PlayerInfo)
    case receivedInvite(peer: PlayerInfo)
    case requestDeclined(peer: PlayerInfo)
    case gameReady(peer: PlayerInfo)

    mutating func reset() {
        self = .idle
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

    mutating func receiveInvite(from peer: PlayerInfo) {
        self = .receivedInvite(peer: peer)
    }

    mutating func setGameReady(with peer: PlayerInfo) {
        self = .gameReady(peer: peer)
    }
}
