//
//  GameplayManager.swift
//  Games
//
//  Created by soyoung on 1/7/26.
//

import Foundation

@Observable
@MainActor
public final class GameplayManager {
    public var state = GameState()

    public var isJumpRequested: Bool = false
    private let maxJumpCount = 2

    private let jumpCooldown: TimeInterval = 0.4
    private let landingCooldown: TimeInterval = 0.3
    
    private var lastJumpTime: TimeInterval = 0
    private var lastLandingTime: TimeInterval = 0

    private var timeSinceLastInput: TimeInterval = 0
    private let inputTimeout: TimeInterval = 0.2

    private var inputProvider: (any GameInputProviding)?
    private var inputTask: Task<Void, Never>?

    public var isRespawning: Bool {
        state.respawn.isRespawning
    }
    
    // MARK: Game End
    public private(set) var endReason: GameEndReason? = nil
    public private(set) var elapsedSeconds: Int = 0
    public private(set) var remainingSeconds: Int? = nil
    public private(set) var lastLandedPlatformIndex: Int = 0

    private var elapsedTime: TimeInterval = 0
    private var timeLimit: TimeInterval? = nil
    private var endCondition: any GameEndCondition

    public init(endCondition: any GameEndCondition = TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 30)) {
        self.endCondition = endCondition
        self.timeLimit = (endCondition as? TimeoutOrFinishEndCondition)?.limit
        if let limit = timeLimit {
            self.remainingSeconds = Int(limit)
        }
    }
    
    public func bind(input: any GameInputProviding) {
        unbind()
        inputProvider = input
        input.start()

        inputTask = Task { [weak self] in
            guard let self else { return }
            let stream = await input.events()
            for await event in stream {
                guard !Task.isCancelled else { break }
                self.handleInput(event)
            }
        }
    }

    public func unbind() {
        inputTask?.cancel()
        inputTask = nil
        inputProvider?.stop()
        inputProvider = nil
    }

    private func handleInput(_ event: GameInputEvent) {
        switch event {
        case .horizontal(let x):
            updateMoveX(x)
        case .jump(let isActive):
            if isActive {
                tryJump()
            }
        }
    }

    private func updateMoveX(_ moveX: Double) {
        state.character.moveX = moveX
        timeSinceLastInput = 0
    }

    private func tryJump() {
        let currentTime = Date().timeIntervalSince1970

        guard currentTime - lastLandingTime > landingCooldown else { return }
        guard currentTime - lastJumpTime > jumpCooldown else { return }
        guard state.character.jumpCount < maxJumpCount else { return }

        state.character.jumpCount += 1
        state.character.isGrounded = false
        isJumpRequested = true

        lastJumpTime = currentTime
        timeSinceLastInput = 0
    }

    // Game Loop Update
    public func update(deltaTime: TimeInterval) {
        guard endReason == nil else { return }
        // 타이머 진행
        elapsedTime += deltaTime
        publishTimeIfNeeded()
        evaluateEndConditionIfNeeded()

        // 입력 처리
        timeSinceLastInput += deltaTime
        if timeSinceLastInput > inputTimeout { // 입력 없이 0.2초가 지났다면
            state.character.moveX = 0 // 정지
        }
    }

    public func resetJumpRequest() {
        isJumpRequested = false
    }

    public func handleContact(_ type: GameContactType) {
        switch type {
        case .ground:
            if !state.character.isGrounded {
                state.character.isGrounded = true
                state.character.jumpCount = 0
                lastLandingTime = Date().timeIntervalSince1970  // 착지 시간 기록
            }
        case .monster:
            requestRespawn(.hitMonster)
        }
    }

    public func handleSeparation(from type: GameContactType) {
        if type == .ground {
            state.character.isGrounded = false
        }
    }
}

// MARK: 리스폰 처리

extension GameplayManager {
    public func requestRespawn(_ reason: RespawnReason) {
        guard state.respawn.isRespawning == false else { return }
        state.respawn.isRespawning = true
        state.respawn.pendingReason = reason
    }

    public func consumeRespawnRequestReason() -> RespawnReason? {
        defer { state.respawn.pendingReason = nil }
        return state.respawn.pendingReason
    }

    public func finishRespawn() {
        state.respawn.isRespawning = false
    }

    public func onPlayerFellOutOfBounds() {
        requestRespawn(.fell)
    }

    public func respawnDelay(for reason: RespawnReason) -> TimeInterval {
        switch reason {
        case .fell:
            return 0
        case .hitMonster:
            return 3.0
        }
    }
}

// MARK: 게임 종료 처리
extension GameplayManager {
    public func setEndCondition(_ condition: any GameEndCondition) {
        endCondition = condition
        timeLimit = (condition as? TimeoutOrFinishEndCondition)?.limit
        // UI 표시값 초기화
        elapsedTime = 0
        elapsedSeconds = 0
        remainingSeconds = timeLimit.map { Int($0) }
        endReason = nil
        lastLandedPlatformIndex = 0
    }

    public func startNewGame() {
        state = GameState()
        isJumpRequested = false

        elapsedTime = 0
        elapsedSeconds = 0
        remainingSeconds = timeLimit.map { Int($0) }
        endReason = nil
        lastLandedPlatformIndex = 0

        timeSinceLastInput = 0
        lastJumpTime = 0
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
