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
    private var physicsCore: PhysicsCore?
    private var cameraSystem: CameraSystem?
    private var platformController: PlatformController?
    private var monsterController: MonsterController?
    private var playerNode: SKSpriteNode?

    private let outOfBoundsMargin: CGFloat = 100

    private var lastUpdateTime: TimeInterval = 0

    // 기울기 효과
    private let maxTiltAngle: CGFloat = 0.2 // 최대 기울기
    private let tiltSpeed: CGFloat = 0.2 // 기울어지는 속도 (0.0 ~ 1.0)
        
    init(size: CGSize, gameplayManager: GameplayManager) {
        self.gameplayManager = gameplayManager
        super.init(size: size)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: PhysicsConstants.gravityDY)
        self.physicsWorld.contactDelegate = self
    }

    required init?(coder: NSCoder) {
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

        // 몬스터 설정
        monsterController = MonsterController(scene: self, cameraSystem: cameraSystem)
        monsterController?.setupInitialMonster()

        // 요소 배치
        setupWalls()
        setupPlayer()

        if let player = playerNode, let playerBody = player.physicsBody {
            // 카메라가 플레이어를 따라가도록 설정
            cameraSystem.follow(player)
            
            // follow 이후 카메라 기준으로 몬스터 위치 보정
            monsterController?.resetBelowCamera()

            // 물리 엔진 연결
            physicsCore = PhysicsCore(body: playerBody)
            playerBody.usesPreciseCollisionDetection = true
        }
    }

    // Game Loop
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard let gameplayManager = gameplayManager,
              let physicsCore = physicsCore,
              let cameraSystem = cameraSystem else {
            return
        }

        gameplayManager.update(deltaTime: deltaTime)
        animatePlayer(moveX: gameplayManager.state.character.moveX)
        
        // Event 점프
        if gameplayManager.isJumpRequested {
            physicsCore.applyJumpImpulse()
            gameplayManager.resetJumpRequest()
        }

        // Physics 상태 적용
        let moveX = gameplayManager.state.character.moveX
        let isGrounded = gameplayManager.state.character.isGrounded
        physicsCore.applyState(deltaTime: deltaTime, moveX: moveX, isGrounded: isGrounded)

        // 카메라 업데이트
        cameraSystem.update()
        
        // 몬스터 업데이트
        monsterController?.update(deltaTime: deltaTime)
        
        updateWalls()
        platformController?.update(cameraY: cameraSystem.cameraNode.position.y, sceneHeight: size.height)

        // 화면(카메라) 아래로 떨어진 경우: 즉시 리스폰
        if let player = playerNode {
            let cameraBottom = cameraSystem.cameraNode.position.y - size.height / 2
            if player.position.y < cameraBottom - outOfBoundsMargin {
                gameplayManager.onPlayerFellOutOfBounds()
            }
        }
        
        if let reason = gameplayManager.consumeRespawnRequestReason() {
            performRespawn(for: reason)
            return
        }
    }

    private func setupWalls() {
        let wallHeight: CGFloat = size.height * 2
        let wallThickness: CGFloat = 50
        let xPos = (size.width / 2) + (wallThickness / 2)

        // 왼쪽 벽
        let leftWall = SKSpriteNode(color: .clear, size: CGSize(width: wallThickness, height: wallHeight))
        leftWall.name = Constants.Game.NodeName.leftWall
        leftWall.position = CGPoint(x: -xPos, y: 0)

        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.size)
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall.rawValue
        leftWall.physicsBody?.restitution = 0.0
        leftWall.physicsBody?.friction = 0.0
        addChild(leftWall)

        // 오른쪽 벽
        let rightWall = SKSpriteNode(color: .clear, size: CGSize(width: wallThickness, height: wallHeight))
        rightWall.name = Constants.Game.NodeName.rightWall
        rightWall.position = CGPoint(x: xPos, y: 0)

        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.size)
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall.rawValue
        rightWall.physicsBody?.restitution = 0.0
        rightWall.physicsBody?.friction = 0.0
        addChild(rightWall)
    }

    private func setupPlayer() {
        let player = SKSpriteNode(imageNamed: AppAsset.Image.character1.name)

        player.name = Constants.Game.NodeName.player
        player.size = CGSize(width: 50, height: 60) // 적절한 크기 조절
        player.position = CGPoint(x: 0, y: -50)

        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false

        player.physicsBody?.categoryBitMask = PhysicsCategory.player.rawValue
        player.physicsBody?.collisionBitMask = PhysicsCategory.playerCollidesWith.rawValue
        player.physicsBody?.contactTestBitMask = PhysicsCategory.playerContactsWith.rawValue
        player.physicsBody?.velocity = .zero

        addChild(player)
        playerNode = player
    }

    private func updateWalls() {
        guard let cameraSystem = cameraSystem else { return }
        let currentCameraY = cameraSystem.cameraNode.position.y

        if let leftWall = childNode(withName: Constants.Game.NodeName.leftWall),
           let rightWall = childNode(withName: Constants.Game.NodeName.rightWall) {
            leftWall.position.y = currentCameraY
            rightWall.position.y = currentCameraY
        }
    }

    // 플레이어 리스폰
    private func performRespawn(for reason: RespawnReason) {
        guard let gameplayManager else { return }
        let startDelay = gameplayManager.respawnDelay(for: reason)

        respawnPlayer(startDelay: startDelay)
    }
    
    private func respawnPlayer(startDelay: TimeInterval) {
        guard let gameplayManager, let player = playerNode else { return }

        // 물리 정지
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false // 잠깐 멈춤

        let wait = SKAction.wait(forDuration: startDelay)
        let moveAndCamera = SKAction.run { [weak self] in
            guard let self,
                  let cameraSystem = self.cameraSystem,
                  let platformController = self.platformController,
                  let player = self.playerNode else {
                self?.gameplayManager?.finishRespawn()
                return
            }

            // 위치 이동 (마지막 안전 발판 + 조금 위)
            let lastSafe = platformController.lastSafePosition
            let target = (lastSafe == .zero) ? CGPoint(x: 0, y: -100) : lastSafe
            player.position = CGPoint(x: target.x, y: target.y + 100)

            cameraSystem.setPosition(CGPoint(x: 0, y: player.position.y - 200))
        }

        // 0.1초 뒤 다시 시작
        let resume = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.playerNode?.physicsBody?.isDynamic = true
                self?.gameplayManager?.finishRespawn()
            }
        ])

        run(.sequence([wait, moveAndCamera, resume]))
    }

    private func animatePlayer(moveX: Double) {
        guard let player = playerNode else { return }

        // 좌우 반전
        if moveX < -0.01 {
            // 왼쪽 이동
            player.xScale = abs(player.xScale)
        } else if moveX > 0.01 {
            // 오른쪽 이동
            player.xScale = -abs(player.xScale)
        }

        // 기울기
        // 목표 각도: 왼쪽으로 가면(+) 오른쪽으로 가면(-) 기울임
        let targetRotation = -CGFloat(moveX) * maxTiltAngle

        // 현재 각도에서 목표 각도로 부드럽게 이동 (Lerp)
        let currentRotation = player.zRotation
        let newRotation = currentRotation + (targetRotation - currentRotation) * tiltSpeed

        player.zRotation = newRotation
    }

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
}

extension GameScene: SKPhysicsContactDelegate {
    // 충돌 시작
    func didBegin(_ contact: SKPhysicsContact) {
        // 충돌한 상대방 찾기
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let otherMask = (maskA == PhysicsCategory.player.rawValue) ? maskB : maskA
        let otherBody = (maskA == PhysicsCategory.player.rawValue) ? contact.bodyB : contact.bodyA

        // 비트마스크를 게임 타입으로 변경
        guard let contactType = convert(from: otherMask) else { return }

        switch contactType {
        case .ground:
            // 땅 로직: 리스폰 중 X
            if gameplayManager?.isRespawning == false,
               let player = playerNode,
               let platformNode = otherBody.node {
                // 위에서 아래로 내려올 때만
                let dy = player.physicsBody?.velocity.dy ?? 0
                if dy <= 5.0 && player.position.y > platformNode.position.y {
                    gameplayManager?.handleContact(.ground)
                    platformController?.updateLastSafePosition(platformNode.position)
                }
            }

        case .monster:
            gameplayManager?.handleContact(.monster)
        }
    }

    // 충돌 끝
    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let otherMask = (maskA == PhysicsCategory.player.rawValue) ? maskB : maskA

        guard let contactType = convert(from: otherMask) else { return }
        // 매니저에게 떨어짐을 전달
        gameplayManager?.handleSeparation(from: contactType)
    }
}
