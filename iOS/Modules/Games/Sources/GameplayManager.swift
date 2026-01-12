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

    public init() {}

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
