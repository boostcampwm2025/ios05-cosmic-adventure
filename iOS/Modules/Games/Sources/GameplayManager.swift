//
//  GameplayManager.swift
//  Games
//
//  Created by soyoung on 1/7/26.
//

import Foundation

/// 게임의 핵심 비즈니스 로직과 상태를 관리하는 중앙 컨트롤러
///
/// `GameplayManager`는 게임 규칙 적용, 상태 관리, 입력 처리를 담당합니다.
/// 렌더링 엔진이나 물리 시뮬레이션과 완전히 독립되어 순수한 게임 로직만 처리합니다.
///
/// ## 주요 기능
///
/// - 캐릭터 상태 관리 (이동, 점프, 접지)
/// - 게임 규칙 집행 (더블 점프, 쿨다운, 타임아웃)
/// - 입력 이벤트 처리 및 변환
/// - 리스폰 로직 관리
/// - 게임 종료 조건 평가
///
/// ## 사용 예제
///
/// ```swift
/// let manager = GameplayManager()
/// let input = FaceTrackingGameInputProvider(inputSystem: inputSystem)
/// manager.bind(input: input)
///
/// func update(_ deltaTime: TimeInterval) {
///     manager.update(deltaTime: deltaTime)
///
///     if manager.isJumpRequested {
///         physicsEngine.applyJumpImpulse()
///         manager.resetJumpRequest()
///     }
/// }
/// ```
///
@Observable
@MainActor
public final class GameplayManager {
    public var state: GameState
    
    public let localPlayerID: UUID
    public let otherPlayerIDs: [UUID]
    
    private var jumpRequestedPlayerIDs: Set<UUID> = []
    private var runtimeByPlayer: [UUID: PlayerRuntime] = [:]
    
    // 조절값
    private let maxJumpCount = 2
    private let jumpCooldown: TimeInterval = 0.4
    private let landingCooldown: TimeInterval = 0.3
    private let inputTimeout: TimeInterval = 0.2

    // TODO: id마다 관리되도록 구현
    private var inputProvider: (any GameInputProviding)?
    private var inputTask: Task<Void, Never>?
    
    // MARK: Game End
    public let gameEnd: GameEndTracker

    public init(
        localPlayerID: UUID,
        otherPlayerIDs: [UUID] = [],
        endCondition: any GameEndCondition = TimeoutOrFinishEndCondition(limit: 60, targetPlatformIndex: 30)
    ) {
        self.localPlayerID = localPlayerID
        self.otherPlayerIDs = otherPlayerIDs
        self.state = GameState(localPlayerID: localPlayerID, otherPlayerIDs: otherPlayerIDs)
                
        self.gameEnd = GameEndTracker(condition: endCondition)
        
        self.initializeRuntimeByPlayer()
    }
    
    private func initializeRuntimeByPlayer() {
        runtimeByPlayer.removeAll(keepingCapacity: true)

        runtimeByPlayer[localPlayerID] = PlayerRuntime()

        for id in otherPlayerIDs where id != localPlayerID {
            runtimeByPlayer[id] = PlayerRuntime()
        }
    }
    
    // TODO: GameInputProviding 네트워크에서 받은 인풋 연결하기
    public func bind(input: any GameInputProviding, for playerID: UUID) {
        unbind()
        inputProvider = input

        inputTask = Task { [weak self] in
            guard let self else { return }
            let stream = await input.events()
            for await event in stream {
                guard !Task.isCancelled else { break }
                self.handleInput(event, for: playerID)
            }
        }
    }

    public func unbind() {
        inputTask?.cancel()
        inputTask = nil
        inputProvider?.stop() // 안전상 로컬에서 한번 더 확인
        inputProvider = nil
    }

    private func handleInput(_ event: GameInputEvent, for playerID: UUID) {
        switch event {
        case .horizontal(let x):
            updateMoveX(x, for: playerID)
        case .jump:
            tryJump(for: playerID)
        }
    }

    // Game Loop Update
    public func update(deltaTime: TimeInterval) {
        guard gameEnd.endReason == nil else { return }
        // 타이머/종료 조건 진행
        gameEnd.tick(deltaTime: deltaTime)

        // 입력 처리(플레이어별)
        for playerID in state.characters.keys {
            runtimeByPlayer[playerID, default: PlayerRuntime()].timeSinceLastInput += deltaTime

            if runtimeByPlayer[playerID, default: PlayerRuntime()].timeSinceLastInput > inputTimeout {
                state.setMoveX(0, for: playerID)
            }
        }
    }
    
    public func handleContact(_ type: GameContactType, for playerID: UUID) {
        switch type {
        case .ground:
            guard let character = state.characters[playerID] else { return }
            
            if !character.isGrounded {
                state.setGrounded(true, for: playerID)
                state.setJumpCount(0, for: playerID)
                runtimeByPlayer[playerID, default: PlayerRuntime()].lastLandingTime = Date().timeIntervalSince1970  // 착지 시간 기록
            }
        case .monster:
            requestRespawn(.hitMonster, for: playerID)
        }
    }
    
    public func handleSeparation(from type: GameContactType, for playerID: UUID) {
        if type == .ground {
            state.setGrounded(false, for: playerID)
        }
    }
}

// MARK: 캐릭터 input 처리

extension GameplayManager {
    private func updateMoveX(_ moveX: Double, for playerID: UUID) {
        state.setMoveX(moveX, for: playerID)
        runtimeByPlayer[playerID, default: PlayerRuntime()].timeSinceLastInput = 0
    }
    
    private func tryJump(for playerID: UUID) {
        let currentTime = Date().timeIntervalSince1970
        
        guard let playRuntime = runtimeByPlayer[playerID],
              let character = state.characters[playerID] else { return }
        
        // 착지 직후 / 연속 점프 쿨다운
        guard currentTime - playRuntime.lastLandingTime > landingCooldown else { return }
        guard currentTime - playRuntime.lastJumpTime > jumpCooldown else { return }
        
        // 최대 점프 횟수 제한
        guard character.jumpCount < maxJumpCount else { return }
        
        // 점프 확정
        state.setJumpCount(character.jumpCount + 1, for: playerID)
        state.setGrounded(false, for: playerID)
        jumpRequestedPlayerIDs.insert(playerID)
        
        // 런타임 갱신
        runtimeByPlayer[playerID]?.lastJumpTime = currentTime
        runtimeByPlayer[playerID]?.timeSinceLastInput = 0
    }
    
    public func isJumpRequested(for playerID: UUID) -> Bool {
        jumpRequestedPlayerIDs.contains(playerID)
    }
    
    public func resetJumpRequest(for playerID: UUID) {
        jumpRequestedPlayerIDs.remove(playerID)
    }
}

// MARK: 리스폰 처리

extension GameplayManager {
    public func isPlayerRespawning(for playerID: UUID) -> Bool {
        state.isRespawning(playerID)
    }
    
    public func requestRespawn(_ reason: RespawnReason, for playerID: UUID) {
        guard state.isRespawning(playerID) == false else { return }
        state.setIsRespawning(true, reason, for: playerID)
    }

    public func consumeRespawnRequestReason(for playerID: UUID) -> RespawnReason? {
        return state.consumePendingRespawnReason(for: playerID)
    }

    public func finishRespawn(for playerID: UUID) {
        state.setIsRespawning(false, for: playerID)
    }

    public func onPlayerFellOutOfBounds(for playerID: UUID) {
        requestRespawn(.fell, for: playerID)
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
        gameEnd.setCondition(condition)
    }

    public func startNewGame() {
        state = GameState(localPlayerID: localPlayerID, otherPlayerIDs: otherPlayerIDs)
        jumpRequestedPlayerIDs.removeAll(keepingCapacity: true)

        gameEnd.startNewGame()
        initializeRuntimeByPlayer()
    }

    public func updateLandedPlatformIndex(_ index: Int) {
        guard gameEnd.endReason == nil else { return }
        gameEnd.updateLandedPlatformIndex(index)
    }
}
