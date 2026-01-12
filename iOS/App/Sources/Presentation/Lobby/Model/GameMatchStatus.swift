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
    case requestDeclined(peer: LobbyExplorer)
    case gameReady(peer: LobbyExplorer)
    case gameStart
}
