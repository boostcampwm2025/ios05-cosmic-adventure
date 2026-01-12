//
//  LobbyConnectionStatus.swift
//  App
//
//  Created by soyoung on 1/12/26.
//

import Foundation

enum GameMatchStatus: Equatable {
    case idle
    case readyToSend(peer: LobbyExplorer)
    case sendingRequest(peer: LobbyExplorer)
    case receivedInvite(peer: LobbyExplorer)
    case requestDeclined(peer: LobbyExplorer)
    case gameReady(peer: LobbyExplorer)
    case gameStart

    mutating func reset() {
        self = .idle
    }

    mutating func select(_ peer: LobbyExplorer) {
        self = .readyToSend(peer: peer)
    }

    mutating func sendRequest() {
        if case .readyToSend(let peer) = self {
            self = .sendingRequest(peer: peer)
        }
    }

    mutating func requestDeclined(by peer: LobbyExplorer) {
        self = .requestDeclined(peer: peer)
    }

    mutating func receiveInvite(from peer: LobbyExplorer) {
        self = .receivedInvite(peer: peer)
    }

    mutating func setGameReady(with peer: LobbyExplorer) {
        self = .gameReady(peer: peer)
    }
}
