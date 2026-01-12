//
//  RespawnState.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/12/26.
//

public enum RespawnReason: Sendable {
    case fell
    case hitMonster
}

public struct RespawnState: Equatable, Sendable {
    public var isRespawning: Bool = false
    public var pendingReason: RespawnReason? = nil
    
    public init(
        isRespawning: Bool = false,
        pendingReason: RespawnReason? = nil
    ) {
        self.isRespawning = isRespawning
        self.pendingReason = pendingReason
    }
}
