//
//  ConnectionSessionManaging.swift
//  NetworkKit
//
//  Created by soyoung on 1/14/26.
//

import Foundation

public protocol ConnectionSessionManaging: AnyObject {
    // MARK: - connection

    func activate(channelId: String?, nickname: String)
    func deactivate()

    // MARK: - call back

    var onInviteReceived: ((String) -> Void)? { get set }
    var onInviteAccepted: ((String) -> Void)? { get set }
    var onInviteDeclined: ((String) -> Void)? { get set }
    var onInviteCancelled: ((String) -> Void)? { get set }
    var onInputReceived: ((String, Data) -> Void)? { get set }
    var onReadyStatusReceived: ((String) -> Void)? { get set }

    // MARK: - action

    func sendInvite(to targetId: String)
    func acceptInvite(from targetId: String)
    func declineInvite(from targetId: String)
    func cancelInvite(to targetId: String)
    func sendInput<T: Codable>(_ data: T, to targetId: String?)
    func sendReadyStatus(to targetId: String)
}

extension ConnectionSessionManaging {
    public func activate(nickname: String) {
        self.activate(channelId: nil, nickname: nickname)
    }

    public func sendInput<T: Codable>(_ data: T) {
        self.sendInput(data, to: nil)
    }
}
