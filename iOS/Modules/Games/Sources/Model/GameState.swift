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
        remotePlayerIDs: [UUID] = [],
    ) {
        self.localPlayerID = localPlayerID
        var dict: [UUID: CharacterState] = [localPlayerID: CharacterState()]
        for id in remotePlayerIDs where id != localPlayerID {
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

    public mutating func setPosition(_ position: CharacterPosition, for id: UUID) {
        ensurePlayer(id)
        guard var character = characters[id] else { return }
        character.position = position
        character.hasNetworkPosition = true
        characters[id] = character
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
        guard var character = characters[id] else { return }

        character.respawn.isRespawning = isRespawning
        if isRespawning {
            character.respawn.pendingReason = reason
        } else {
            character.respawn.pendingReason = nil
        }

        characters[id] = character
    }
    
    public mutating func consumePendingRespawnReason(for id: UUID) -> RespawnReason? {
        guard var character = characters[id] else { return nil }
        let reason = character.respawn.pendingReason
        character.respawn.pendingReason = nil
        characters[id] = character
        return reason
    }
    
    mutating func setLastSafePosition(_ pos: CharacterPosition, for playerID: UUID) {
        guard var character = characters[playerID] else { return }
        character.respawn.lastSafePosition = pos
        characters[playerID] = character
    }
}
