//
//  GameplayManager.swift
//  Games
//
//  Created by soyoung on 1/7/26.
//

import Foundation

@Observable
public final class GameplayManager {
    public var state = CharacterState()

    public var isJumpRequested: Bool = false
    private let maxJumpCount = 2

    // 0.4초 동안은 연속 점프 금지 (얼굴 인식 속도가 너무 빨라서 필요)
    private let jumpCooldown: TimeInterval = 0.4
    private var lastJumpTime: TimeInterval = 0

    // InputSystem DeadZone 이벤트 처리
    private var timeSinceLastInput: TimeInterval = 0
    private let inputTimeout: TimeInterval = 0.2

    public init() {}

    // InputSystem event 연결
    public func updateInput(moveX: Double) {
        state.moveX = moveX
        timeSinceLastInput = 0
    }

    public func tryJump() {
        // 현재 시간
        let currentTime = Date().timeIntervalSince1970

        // 쿨타임 체크 - 마지막 점프하고 0.4초 지났는지 체크
        if currentTime - lastJumpTime > jumpCooldown {

            // 점프 횟수 체크
            if state.jumpCount < maxJumpCount {
                state.jumpCount += 1
                state.isGrounded = false

                isJumpRequested = true

                // 마지막 점프 시간 갱신 (쿨타임 시작)
                lastJumpTime = currentTime
                timeSinceLastInput = 0
            }
        }
    }

    // Game Loop Update
    public func update(deltaTime: TimeInterval) {
        timeSinceLastInput += deltaTime

        if timeSinceLastInput > inputTimeout { // 입력 없이 0.2초가 지났다면
            state.moveX = 0 // 정지
        }
    }

    public func resetJumpRequest() {
        isJumpRequested = false
    }

    public func handleContact(_ type: GameContactType) {
        switch type {
        case .ground:
            // 땅에 닿으면 점프 횟수 초기화
            if !state.isGrounded {
                state.isGrounded = true
                state.jumpCount = 0
            }
        case .monster:
            break
        }
    }

    public func handleSeparation(from type: GameContactType) {
        if type == .ground {
            state.isGrounded = false
        }
    }
}
