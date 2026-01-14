//
//  GameState.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/12/26.
//

import Foundation

public struct GameState: Equatable, Sendable {
    public private(set) var characters: [UUID: CharacterState]

    /// 로컬 플레이어 ID (기본)
    public let localPlayerID: UUID

    public init(
        localPlayerID: UUID,
        opponentPlayerIDs: [UUID] = [],
    ) {
        self.localPlayerID = localPlayerID
        var dict: [UUID: CharacterState] = [localPlayerID: CharacterState()]
        for id in opponentPlayerIDs where id != localPlayerID {
            dict[id] = CharacterState()
        }
        self.characters = dict
    }
    
    // MARK: - player APIs
    
    public mutating func ensurePlayer(_ id: UUID) {
        if characters[id] == nil {
            characters[id] = .init()
        }
    }

    public mutating func setMoveX(_ moveX: Double, for id: UUID) {
        characters[id, default: .init()].moveX = moveX
    }

    public mutating func setGrounded(_ grounded: Bool, for id: UUID) {
        characters[id, default: .init()].isGrounded = grounded
    }
    
    public mutating func setJumpCount(_ jumpCount: Int, for id: UUID) {
        characters[id, default: .init()].jumpCount = jumpCount
    }
    
    public func isRespawning(_ id: UUID) -> Bool {
        characters[id, default: .init()].respawn.isRespawning
    }
    
    public mutating func setIsRespawning(
        _ isRespawning: Bool,
        _ reason: RespawnReason? = nil,
        for id: UUID
    ) {
        ensurePlayer(id)
        guard var cs = characters[id] else { return }

        cs.respawn.isRespawning = isRespawning
        if isRespawning {
            cs.respawn.pendingReason = reason
        } else {
            cs.respawn.pendingReason = nil
        }

        characters[id] = cs
    }
    
    public mutating func consumePendingRespawnReason(for id: UUID) -> RespawnReason? {
        guard var cs = characters[id] else { return nil }
        let reason = cs.respawn.pendingReason
        cs.respawn.pendingReason = nil
        characters[id] = cs
        return reason
    }
}
