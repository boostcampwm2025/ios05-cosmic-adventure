//
//  GameRecord.swift
//  StorageKit
//
//  Created by 강윤서 on 1/13/26.
//

import Foundation
import SwiftData

@Model
public class GameRecord {
    public var id: UUID
    public var score: Int
    public var playDate: Date
    public var gameMode: Int
    public var playTime: TimeInterval
    
    public init(
        id: UUID,
        score: Int,
        playDate: Date,
        gameMode: Int,
        playTime: TimeInterval
    ) {
        self.id = id
        self.score = score
        self.playDate = playDate
        self.gameMode = gameMode
        self.playTime = playTime
    }
}
