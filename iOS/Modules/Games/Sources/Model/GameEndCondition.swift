//
//  GameEndCondition.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/13/26.
//

import Foundation

public protocol GameEndCondition {
    func check(elapsedTime: TimeInterval, lastLandedPlatformIndex: Int) -> GameEndReason?
}

public struct TimeoutOrFinishEndCondition: GameEndCondition {
    public let limit: TimeInterval
    public let goalPlatformIndex: Int
    
    public init(limit: TimeInterval, targetPlatformIndex: Int) {
        self.limit = limit
        self.goalPlatformIndex = targetPlatformIndex
    }
    
    public func check(elapsedTime: TimeInterval, lastLandedPlatformIndex: Int) -> GameEndReason? {
        // 동일 프레임에 둘 다 만족하면 '결승 도착'을 우선 처리
        if lastLandedPlatformIndex >= goalPlatformIndex {
            return .reachedFinish
        }
        if elapsedTime >= limit {
            return .timeout
        }
        return nil
    }
}
