//
//  NetworkGameEndDTO.swift
//  NetworkKit
//
//  Created by sungkug_apple_developer_ac on 1/27/26.
//

import Foundation

public enum GameEndReasonCode: Int, Codable, Sendable {
    case timeout = 0
    case reachedFinish = 1
    case quit = 2
}

public struct NetworkGameEndDTO: Codable, Sendable {
    public let reason: GameEndReasonCode
    public let winnerId: UUID?
    public let winnerElapsedSeconds: Int?
    public let winnerName: String?
    public let opponentName: String?

    public init(
        reason: GameEndReasonCode,
        winnerId: UUID? = nil,
        winnerElapsedSeconds: Int? = nil,
        winnerName: String? = nil,
        opponentName: String? = nil
    ) {
        self.reason = reason
        self.winnerId = winnerId
        self.winnerElapsedSeconds = winnerElapsedSeconds
        self.winnerName = winnerName
        self.opponentName = opponentName
    }
}
