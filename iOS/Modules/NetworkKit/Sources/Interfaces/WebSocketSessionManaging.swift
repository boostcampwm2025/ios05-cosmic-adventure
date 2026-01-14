//
//  WebSocketSessionManaging.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public protocol WebSocketSessionManaging: ConnectionSessionManaging {
    var players: [WebSocketPlayer] { get }
    var isConnected: Bool { get }
    var mySessionId: String? { get }
    
    var onPlayersUpdated: (([WebSocketPlayer]) -> Void)? { get set }
    var onPlayerJoined: ((WebSocketPlayer) -> Void)? { get set }
    var onPlayerLeft: ((String) -> Void)? { get set }
    var onConnectionStateChanged: ((Bool) -> Void)? { get set }
}
