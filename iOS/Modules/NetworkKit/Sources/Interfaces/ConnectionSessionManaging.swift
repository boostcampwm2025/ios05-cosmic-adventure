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

    var onInviteReceived: ((UUID) -> Void)? { get set }
    var onInviteAccepted: ((UUID) -> Void)? { get set }
    var onInviteDeclined: ((UUID) -> Void)? { get set }
    var onInviteCancelled: ((UUID) -> Void)? { get set }
    var onInputReceived: ((UUID, Data) -> Void)? { get set }
    var onReadyStatusReceived: ((UUID) -> Void)? { get set }
    var onVideoReceived: ((UUID, Data) -> Void)? { get set }

    // MARK: - action

    func sendInvite(to targetId: UUID)
    func acceptInvite(from targetId: UUID)
    func declineInvite(from targetId: UUID)
    func cancelInvite(to targetId: UUID)
    func sendInput<T: Codable>(_ data: T, to targetId: UUID?)
    func sendReadyStatus(to targetId: UUID)
    func sendVideo(_ data: Data, to targetId: UUID?)

    func getLatency(for playerId: UUID) -> Double?
}

extension ConnectionSessionManaging {
    public func activate(nickname: String) {
        self.activate(channelId: nil, nickname: nickname)
    }

    public func sendInput<T: Codable>(_ data: T) {
        self.sendInput(data, to: nil)
    }

    public func sendVideo(_ data: Data) {
        self.sendVideo(data, to: nil)
    }
}
