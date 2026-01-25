//
//  GameEndTracker.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/15/26.
//

import Foundation
import Observation

/// 게임 종료 관련 상태(타이머/결승)와 판정을 전담하는 객체
///
/// - 역할: elapsed/remaining 시간 갱신, 마지막 착지 플랫폼 인덱스 갱신, 종료 조건 평가
@Observable
@MainActor
public final class GameEndTracker {
    public private(set) var endReason: GameEndReason? = nil
    public private(set) var elapsedSeconds: Int = 0
    public private(set) var remainingSeconds: Int? = nil
    public private(set) var lastLandedPlatformIndex: Int = 0

    private var elapsedTime: TimeInterval = 0
    private var timeLimit: TimeInterval? = nil
    private(set) var endCondition: any GameEndCondition

    public init(condition: any GameEndCondition) {
        self.endCondition = condition
        self.timeLimit = (condition as? TimeoutOrFinishEndCondition)?.limit
        self.remainingSeconds = timeLimit.map { Int($0) }
    }

    public func setCondition(_ condition: any GameEndCondition) {
        endCondition = condition
        timeLimit = (condition as? TimeoutOrFinishEndCondition)?.limit
        startNewGame()
    }

    public func startNewGame() {
        elapsedTime = 0
        elapsedSeconds = 0
        remainingSeconds = timeLimit.map { Int($0) }
        endReason = nil
        lastLandedPlatformIndex = 0
    }

    public func tick(deltaTime: TimeInterval) {
        guard endReason == nil else { return }
        elapsedTime += deltaTime
        publishTimeIfNeeded()
        evaluateEndConditionIfNeeded()
    }

    public func updateLandedPlatformIndex(_ index: Int) {
        guard endReason == nil else { return }
        if index > lastLandedPlatformIndex {
            lastLandedPlatformIndex = index
        }
        evaluateEndConditionIfNeeded()
    }

    private func evaluateEndConditionIfNeeded() {
        guard endReason == nil else { return }
        if let reason = endCondition.check(elapsedTime: elapsedTime, lastLandedPlatformIndex: lastLandedPlatformIndex) {
            endReason = reason
        }
    }

    private func publishTimeIfNeeded() {
        let sec = Int(elapsedTime)
        if sec != elapsedSeconds {
            elapsedSeconds = sec
            if let limit = timeLimit {
                let remain = max(0, Int(limit) - sec)
                remainingSeconds = remain
            }
        }
    }
}
