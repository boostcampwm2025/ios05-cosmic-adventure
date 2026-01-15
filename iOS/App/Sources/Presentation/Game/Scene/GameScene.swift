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

    // PlayerID 기반으로 캐릭터 컨트롤러를 관리
    private let localPlayerID: UUID
    private let otherPlayerIDs: [UUID]
    private var characterControllers: [UUID: CharacterController] = [:]
    
    private let outOfBoundsMargin: CGFloat = 100
    private var lastUpdateTime: TimeInterval = 0

    init(
        size: CGSize,
        gameplayManager: GameplayManager,
        localPlayerID: UUID,
        otherPlayerIDs: [UUID] = []
    ) {
        self.gameplayManager = gameplayManager
        self.localPlayerID = localPlayerID
        self.otherPlayerIDs = otherPlayerIDs
        super.init(size: size)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: PhysicsConstants.gravityDY)
        self.physicsWorld.contactDelegate = self
    }

    required init?(coder: NSCoder) {
        self.localPlayerID = UUID()
        self.otherPlayerIDs = []
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
        platformController?.setupInitialPlatforms()
        setupWalls()

        // 몬스터 설정
        monsterController = MonsterController(scene: self, cameraSystem: cameraSystem)
        monsterController?.setupInitialMonster()

        // 캐릭터 설정 (항상 로컬 플레이어는 생성)
        let localController = CharacterController(scene: self, cameraSystem: cameraSystem, playerRole: .me)
        localController.setupPlayer()
        if let node = localController.playerNode {
            node.name = "\(L10N.Game.NodeName.player):\(localPlayerID.uuidString)"
        }
        characterControllers[localPlayerID] = localController
        
        // 상대 플레이어들 생성
        for id in otherPlayerIDs where id != localPlayerID {
            let opponentController = CharacterController(scene: self, cameraSystem: cameraSystem, playerRole: .others)
            
            opponentController.setupPlayer()
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
        
        // 몬스터 업데이트
        monsterController?.update(deltaTime: deltaTime)
        
        platformController?.update(cameraY: cameraSystem.cameraNode.position.y, cullBelowY: monsterController?.topY)
        
        if let localController = characterControllers[localPlayerID] {
            // 플랫폼 충돌 창 업데이트: 점프 중 머리 박힘 방지
            platformController?.updateCollisions(playerY: localController.positionY, playerDY: localController.velocityDY)
        }
        
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

    // MARK: Helper
    
    // BitMask -> GameContactType으로 변환
    private func convert(from mask: UInt32) -> GameContactType? {
        switch mask {
        case PhysicsCategory.ground.rawValue:
            return .ground
        case PhysicsCategory.monster.rawValue:
            return .monster
        default:
            return nil
        }
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
        let playerBody = (maskA == PhysicsCategory.player.rawValue) ? contact.bodyA : contact.bodyB
        let otherBody = (maskA == PhysicsCategory.player.rawValue) ? contact.bodyB : contact.bodyA
        let otherMask = otherBody.categoryBitMask
        
        let playerID = playerID(from: playerBody) ?? localPlayerID
        
        // 비트마스크를 게임 타입으로 변경
        guard let contactType = convert(from: otherMask) else { return }

        switch contactType {
        case .ground:
            // 땅 로직: 리스폰 중 X
            if gameplayManager?.isPlayerRespawning(for: playerID) == false,
               let platformNode = otherBody.node {
                
                // 현재/이전/다음 플랫폼만 접지 판정 대상으로 (충돌 창과 동일)
                guard platformController?.isInCollisionWindow(platformNode) == true else {
                    return
                }
                
                // 위에서 밟는 접촉만 착지로 인정
                let playerIsBodyA = (maskA == PhysicsCategory.player.rawValue)
                let normalDY = contact.contactNormal.dy
                
                // player가 위에서 플랫폼을 밟으면
                // - player가 bodyA인 경우 normal은 아래 방향(음수)
                // - player가 bodyB인 경우 normal은 위 방향(양수)
                let isLandingFromAbove = playerIsBodyA ? (normalDY < -0.2) : (normalDY > 0.2)
                
                guard isLandingFromAbove else { return }
                
                gameplayManager?.handleContact(.ground, for: playerID)
                // TODO: 리스폰 구역 각 컨트롤러가 담당하도록 변경
                // 로컬 플레이어의 진행도만 기록
                if playerID == localPlayerID {
                    platformController?.updateLastSafePlatform(platformNode)
                    if let idx = platformController?.lastSafePlatformIndex {
                        gameplayManager?.updateLandedPlatformIndex(idx)
                    }
                }
            }

        case .monster:
            gameplayManager?.handleContact(.monster, for: playerID)
        }
    }

    // 충돌 끝
    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let playerBody = (maskA == PhysicsCategory.player.rawValue) ? contact.bodyA : contact.bodyB
        let otherBody = (maskA == PhysicsCategory.player.rawValue) ? contact.bodyB : contact.bodyA
        let otherMask = otherBody.categoryBitMask

        guard let contactType = convert(from: otherMask) else { return }
        // 매니저에게 떨어짐을 전달
        let playerID = playerID(from: playerBody) ?? localPlayerID

        gameplayManager?.handleSeparation(from: contactType, for: playerID)
    }
}

// MARK: 리스폰 처리

extension GameScene {
    // 플레이 영역 밖일 때 리스폰
    private func handleOutOfBounds(cameraSystem: CameraSystem, gameplayManager: GameplayManager) {
        let cameraBottom = cameraSystem.cameraNode.position.y - size.height / 2
        
        for (id, controller) in characterControllers {
            if controller.isBelow(cameraBottom: cameraBottom, margin: outOfBoundsMargin) {
                gameplayManager.onPlayerFellOutOfBounds(for: id)
            }
        }
    }

    private func handleRespawnRequest(gameplayManager: GameplayManager) {
        for id in characterControllers.keys {
            guard let reason = gameplayManager.consumeRespawnRequestReason(for: id) else {
                continue
            }
            performRespawn(for: reason, playerID: id)
        }
    }
    
    // 플레이어 리스폰
    private func performRespawn(for reason: RespawnReason, playerID: UUID) {
        guard let gameplayManager else { return }
        let startDelay = gameplayManager.respawnDelay(for: reason)

        respawnPlayer(startDelay: startDelay, reason: reason, playerID: playerID)
    }
    
    private func respawnPlayer(startDelay: TimeInterval, reason: RespawnReason, playerID: UUID) {
        guard let characterController = characterControllers[playerID],
              let platformController else { return }

        characterController.freezePhysics()
        characterController.beginRespawn(reason: reason, duration: startDelay)
        
        // TODO: 현재 로컬 기준으로 리스폰 하지만 나중에 각 리스폰 포인트를 관리하게 변경
        characterController.moveToRespawn(lastSafePosition: platformController.lastSafePosition)

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
