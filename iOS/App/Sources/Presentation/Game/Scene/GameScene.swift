//
//  GameScene.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

import Games
import GameEngineCore
import SpriteKit

final class GameScene: SKScene {
    private var gameplayManager: GameplayManager?
    private var cameraSystem: CameraSystem?
    private var platformController: PlatformController?
    private var monsterController: MonsterController?

    // 플레이어 메타(아바타) - 전달이 없으면 기본값 사용
    private let localExplorer: LobbyExplorer?
    private let otherExplorersByID: [UUID: LobbyExplorer]
    
    // PlayerID 기반으로 캐릭터 컨트롤러를 관리
    private let localPlayerID: UUID
    private let otherPlayerIDs: [UUID]
    private var characterControllers: [UUID: CharacterController] = [:]
    
    private let outOfBoundsMargin: CGFloat = 100
    private var lastUpdateTime: TimeInterval = 0

    private var goalPlatformIndex: Int
    
    init(
        size: CGSize,
        gameplayManager: GameplayManager,
        localExplorer: LobbyExplorer? = nil,
        otherExplorersByID: [UUID: LobbyExplorer] = [:]
    ) {
        self.gameplayManager = gameplayManager
        self.localPlayerID = gameplayManager.localPlayerID
        self.otherPlayerIDs = gameplayManager.otherPlayerIDs
        self.localExplorer = localExplorer
        self.otherExplorersByID = otherExplorersByID
        self.goalPlatformIndex = gameplayManager.getGoalPlatformIndex()
        super.init(size: size)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: PhysicsConstants.gravityDY)
        self.physicsWorld.contactDelegate = self
    }

    required init?(coder: NSCoder) {
        self.localPlayerID = UUID()
        self.otherPlayerIDs = []
        self.localExplorer = nil
        self.otherExplorersByID = [:]
        self.goalPlatformIndex = 1
        super.init(coder: coder)
    }

    override func didMove(to view: SKView) {
        // 기본 설정
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = .clear

        // 카메라 설정
        let cameraSystem = CameraSystem(scene: self)
        self.cameraSystem = cameraSystem
        
        // 맵 설정
        platformController = PlatformController(scene: self)
        platformController?.setupInitialPlatforms(goalIndex: goalPlatformIndex)
        setupWalls()

        // 캐릭터 설정 (항상 로컬 플레이어는 생성)
        let localController = CharacterController(scene: self, cameraSystem: cameraSystem, playerRole: .me)
        let localAvatar = localExplorer?.avatar ?? .character1
        localController.setupPlayer(characterType: localAvatar)
        if let node = localController.playerNode {
            node.name = "\(L10N.Game.NodeName.player):\(localPlayerID.uuidString)"
        }
        characterControllers[localPlayerID] = localController
        
        // 상대 플레이어들 생성
        for id in otherPlayerIDs where id != localPlayerID {
            let opponentController = CharacterController(scene: self, cameraSystem: cameraSystem, playerRole: .others)
            let opponentAvatar = otherExplorersByID[id]?.avatar ?? .character1
            opponentController.setupPlayer(characterType: opponentAvatar)
            if let node = opponentController.playerNode {
                node.name = "\(L10N.Game.NodeName.player):\(id.uuidString)"
            }
            characterControllers[id] = opponentController
        }
        
        if let player = characterControllers[localPlayerID]?.playerNode {
            // 카메라가 로컬 플레이어를 따라가도록 설정
            cameraSystem.follow(player)
        }
        
        // 몬스터 설정
        monsterController = MonsterController(scene: self, cameraSystem: cameraSystem)
        monsterController?.setupInitialMonster()
        
        updatePlatformCollisions(deltaTime: 0)
    }

    // Game Loop
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard let gameplayManager = gameplayManager,
              let cameraSystem = cameraSystem else {
            return
        }
        
        gameplayManager.update(deltaTime: deltaTime)
        
        if gameplayManager.gameEnd.endReason != nil {
            // 종료 시 모든 캐릭터 물리 정지
            for (_, controller) in characterControllers {
                controller.freezePhysics()
            }
            return
        }

        // 모든 플레이어의 상태를 반영
        for (id, controller) in characterControllers {
            guard let cs = gameplayManager.state.characters[id] else { continue }

            controller.applyMovement(
                deltaTime: deltaTime,
                moveX: cs.moveX,
                isGrounded: cs.isGrounded
            )

            if gameplayManager.isJumpRequested(for: id) {
                controller.applyJump()
                gameplayManager.resetJumpRequest(for: id)
            }
        }
        // 맵 업데이트
        updateWalls()
        
        // 카메라 업데이트
        cameraSystem.update()
        
        // 몬스터 업데이트 (플랫폼과 겹치지 않도록 제한)
        let safePlatformTopY = platformController?.safePlatformTopY()
        monsterController?.update(deltaTime: deltaTime, platformTopY: safePlatformTopY)
        
        // 플랫폼 추가 생성 및 제거(모든 캐릭터 기준)
        let playerYs = characterControllers.values.compactMap { $0.playerNode?.position.y }
        let highestPlayerY = playerYs.max() ?? cameraSystem.cameraNode.position.y
        let lowestPlayerY = playerYs.min() ?? cameraSystem.cameraNode.position.y

        platformController?.update(requiredTopY: highestPlayerY, cullBelowY: lowestPlayerY)
        
        updatePlatformCollisions(deltaTime: deltaTime)
        
        // 플레이영역 아래로 떨어진 경우 처리
        handleOutOfBounds(cameraSystem: cameraSystem, gameplayManager: gameplayManager)
        
        // 리스폰 적용 여부 판단
        handleRespawnRequest(gameplayManager: gameplayManager)
    }

    private func setupWalls() {
        let wallHeight: CGFloat = size.height * 2
        let wallThickness: CGFloat = 50
        let xPos = (size.width / 2) + (wallThickness / 2)

        // 왼쪽 벽
        let leftWall = SKSpriteNode(color: .clear, size: CGSize(width: wallThickness, height: wallHeight))
        leftWall.name = L10N.Game.NodeName.leftWall
        leftWall.position = CGPoint(x: -xPos, y: 0)

        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.size)
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall.rawValue
        leftWall.physicsBody?.restitution = 0.0
        leftWall.physicsBody?.friction = 0.0
        addChild(leftWall)

        // 오른쪽 벽
        let rightWall = SKSpriteNode(color: .clear, size: CGSize(width: wallThickness, height: wallHeight))
        rightWall.name = L10N.Game.NodeName.rightWall
        rightWall.position = CGPoint(x: xPos, y: 0)

        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.size)
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall.rawValue
        rightWall.physicsBody?.restitution = 0.0
        rightWall.physicsBody?.friction = 0.0
        addChild(rightWall)
    }

    private func updateWalls() {
        guard let cameraSystem = cameraSystem else { return }
        let currentCameraY = cameraSystem.cameraNode.position.y

        if let leftWall = childNode(withName: L10N.Game.NodeName.leftWall),
           let rightWall = childNode(withName: L10N.Game.NodeName.rightWall) {
            leftWall.position.y = currentCameraY
            rightWall.position.y = currentCameraY
        }
    }
    
    private func updatePlatformCollisions(deltaTime: TimeInterval) {
        // 플레이어별로 플랫폼 충돌 카테고리를 독립적으로 갱신
        let localBottomY = characterControllers[localPlayerID]?.bottomY
        let localDY = characterControllers[localPlayerID]?.velocityDY

        let otherID = otherPlayerIDs.first(where: { $0 != localPlayerID })
        let otherBottomY = otherID.flatMap { characterControllers[$0]?.bottomY }
        let otherDY = otherID.flatMap { characterControllers[$0]?.velocityDY }

        platformController?.updateCollisions(
            localBottomY: localBottomY,
            localDY: localDY,
            otherBottomY: otherBottomY,
            otherDY: otherDY,
            deltaTime: deltaTime
        )
    }

    // MARK: Helper
    
    // BitMask -> GameContactType으로 변환
    private func convert(from mask: UInt32) -> GameContactType? {
        if (mask & PhysicsCategory.anyGround.rawValue) != 0 {
            return .ground
        }
        if mask == PhysicsCategory.monster.rawValue {
            return .monster
        }
        return nil
    }
    
    private func playerID(from body: SKPhysicsBody) -> UUID? {
        guard let name = body.node?.name else { return nil }
        let prefix = "\(L10N.Game.NodeName.player):"
        guard name.hasPrefix(prefix) else { return nil }
        let uuidString = String(name.dropFirst(prefix.count))
        return UUID(uuidString: uuidString)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    // 충돌 시작
    func didBegin(_ contact: SKPhysicsContact) {
        // 충돌한 상대방 찾기
        let maskA = contact.bodyA.categoryBitMask
        let aIsPlayer = (maskA & PhysicsCategory.anyPlayer.rawValue) != 0
        let playerBody = aIsPlayer ? contact.bodyA : contact.bodyB
        let otherBody = aIsPlayer ? contact.bodyB : contact.bodyA
        let otherMask = otherBody.categoryBitMask
        
        let playerID = playerID(from: playerBody) ?? localPlayerID
        
        // 비트마스크를 게임 타입으로 변경
        guard let contactType = convert(from: otherMask) else { return }

        switch contactType {
        case .ground:
            // 땅 로직: 리스폰 중 X
            if gameplayManager?.isPlayerRespawning(for: playerID) == false,
               let platformNode = otherBody.node {
                
                // 착지 판정: 하강 중(velocity.dy <= 0)일 때만 땅으로 인정
                // contactNormal은 기기/상황에 따라 0에 가깝게 나오는 경우가 있어 보조로만 사용
                let isFalling = playerBody.velocity.dy <= 0
                guard isFalling else { return }
                
                let playerIsBodyA = (playerBody == contact.bodyA)
                let normalDY = contact.contactNormal.dy
                let normalOK = playerIsBodyA ? (normalDY < -0.05) : (normalDY > 0.05)
                
                // normal이 애매하게 0에 가까워도 하강 중이면 grounded를 갱신해 플랫폼 위에 설 수 있게 한다
                if !normalOK {

                }
                
                gameplayManager?.handleContact(.ground, for: playerID)
                
                if playerID == localPlayerID {
                    platformController?.updateLastSafePlatform(platformNode)
                    if let idx = platformController?.lastSafePlatformIndex,
                       let safe = platformController?.lastSafePosition {
                        // 로컬 플레이어의 진행도만 기록
                        gameplayManager?.updateLandedPlatformIndex(idx)
                        // 로컬 플레이어의 마지막 리스폰 위치만 기록
                        gameplayManager?.updateLastSafePosition(
                            RespawnPosition(x: Double(safe.x), y: Double(safe.y)),
                            for: localPlayerID
                        )
                    }
                }
            }

        case .monster:
            // 로컬 플레이만 충돌 인식
            if playerID == localPlayerID {
                gameplayManager?.handleContact(.monster, for: playerID)
            }
        }
    }

    // 충돌 끝
    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let aIsPlayer = (maskA & PhysicsCategory.anyPlayer.rawValue) != 0
        let playerBody = aIsPlayer ? contact.bodyA : contact.bodyB
        let otherBody = aIsPlayer ? contact.bodyB : contact.bodyA
        let otherMask = otherBody.categoryBitMask

        guard let contactType = convert(from: otherMask) else { return }
        // 매니저에게 떨어짐을 전달
        let playerID = playerID(from: playerBody) ?? localPlayerID

        gameplayManager?.handleSeparation(from: contactType, for: playerID)
    }
}

// MARK: 리스폰 처리

extension GameScene {
    // 로컬 플레이어가 플레이 영역 밖일 때 리스폰
    private func handleOutOfBounds(cameraSystem: CameraSystem, gameplayManager: GameplayManager) {
        let cameraBottom = cameraSystem.cameraNode.position.y - size.height / 2
        
        if let controller = characterControllers[localPlayerID],
           controller.isBelow(cameraBottom: cameraBottom, margin: outOfBoundsMargin) {
            gameplayManager.onPlayerFellOutOfBounds(for: localPlayerID)
        }
    }

    private func handleRespawnRequest(gameplayManager: GameplayManager) {
        for id in characterControllers.keys {
            guard let reason = gameplayManager.consumeRespawnRequestReason(for: id) else { continue }

            let base: CGPoint

            if id == localPlayerID {
                base = platformController?.lastSafePosition ?? .zero
            } else {
                guard let rp = gameplayManager.consumeRespawnPosition(for: id) else { continue }
                base = CGPoint(x: rp.x, y: rp.y)
            }
            
            performRespawn(for: reason, playerID: id, respawnBasePosition: base)
        }
    }
    
    // 플레이어 리스폰
    private func performRespawn(for reason: RespawnReason,
                                playerID: UUID,
                                respawnBasePosition: CGPoint
    ) {
        guard let gameplayManager else { return }
        let startDelay = gameplayManager.respawnDelay(for: reason)

        respawnPlayer(
            startDelay: startDelay,
            reason: reason,
            playerID: playerID,
            respawnBasePosition: respawnBasePosition
        )
    }
    
    private func respawnPlayer(startDelay: TimeInterval,
                               reason: RespawnReason,
                               playerID: UUID,
                               respawnBasePosition: CGPoint
    ) {
        guard let characterController = characterControllers[playerID] else { return }

        characterController.freezePhysics()
        characterController.beginRespawn(reason: reason, duration: startDelay)
        
        characterController.moveToRespawn(lastSafePosition: respawnBasePosition)

        let wait = SKAction.wait(forDuration: startDelay)

        // 0.1초 뒤 다시 시작
        let resume = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                guard let self,
                      let controller = self.characterControllers[playerID] else {
                    self?.gameplayManager?.finishRespawn(for: playerID)
                    return
                }

                controller.resumePhysics()
                controller.endRespawn()
                self.gameplayManager?.finishRespawn(for: playerID)
            }
        ])

        run(.sequence([wait, resume]))
    }
}
