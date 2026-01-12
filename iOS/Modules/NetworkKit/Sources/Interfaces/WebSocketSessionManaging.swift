//
//  WebSocketSessionManaging.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public protocol WebSocketSessionManaging: AnyObject {
    var players: [WebSocketPlayer] { get }
    var isConnected: Bool { get }
    var mySessionId: String? { get }
    
    var onPlayersUpdated: (([WebSocketPlayer]) -> Void)? { get set }
    var onPlayerJoined: ((WebSocketPlayer) -> Void)? { get set }
    var onPlayerLeft: ((String) -> Void)? { get set }
    var onInviteReceived: ((String) -> Void)? { get set }
    var onInviteAccepted: ((String) -> Void)? { get set }
    var onInviteDeclined: ((String) -> Void)? { get set }
    var onInviteCancelled: ((String) -> Void)? { get set }
    var onInputReceived: ((String, String) -> Void)? { get set }
    var onConnectionStateChanged: ((Bool) -> Void)? { get set }
    
    func activate(channelId: String, nickname: String)
    func deactivate()
    func sendInvite(to playerId: String)
    func acceptInvite(from playerId: String)
    func declineInvite(from playerId: String)
    func cancelInvite(to playerId: String)
    func sendInput(_ data: String, to playerId: String)
}
