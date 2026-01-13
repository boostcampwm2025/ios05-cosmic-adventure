//
//  ConnectionSessionProvider.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation

public enum LocalNetworkError: Error {
    case denied
    case unknown
}

public protocol ConnectionSessionProvider {
    var nearbyPlayer: [Peer] { get }

    var onPermissionResult: ((Result<Void, LocalNetworkError>) -> Void)? { get set }
    var onInviteReceived: ((String) -> Void)? { get set }
    var onInviteAccepted: ((String) -> Void)? { get set }
    var onInviteDeclined: ((String) -> Void)? { get set }
    var onInviteCancelled: ((String) -> Void)? { get set }
    var onInputReceived: ((String, Data) -> Void)? { get set }

    func activate(nickname: String)
    func deactive()
    func sendInvite(to peer: String)
    func cancelInvite(from peer: String)
    func acceptInvite(from peer: String)
    func declineInvite(from peer: String)

}
