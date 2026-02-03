//
//  RespawnState.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/12/26.
//

public struct RespawnPosition: Sendable, Codable, Equatable {
    public var x: Double
    public var y: Double
    public var platformIndex: Int
    public static let zero = RespawnPosition(x: 0, y: 0)

    public init(x: Double, y: Double, platformIndex: Int = 0) {
        self.x = x
        self.y = y
        self.platformIndex = platformIndex
    }
}

public enum RespawnReason: Sendable {
    case fell
    case hitMonster
}

public struct RespawnState: Equatable, Sendable {
    public var lastSafePosition: RespawnPosition = .zero
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
