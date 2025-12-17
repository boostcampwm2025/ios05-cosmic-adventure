//
//  GameScene.swift
//  Engine
//
//  Created by 강윤서 on 12/17/25.
//

import SpriteKit
import OSLog

import Core

public class GameScene: SKScene {

    private var player: SKSpriteNode!
    private var moveDirection: CGFloat = 0  /// -1(왼쪽), 0(정지), 1(오른쪽)
    private var logger = Logger()

    // 카메라 추적용
    private var gameCamera: SKCameraNode!
    private var maxPlayerY: CGFloat = 0  /// 플레이어가 도달한 최고 높이

    public override func didMove(to view: SKView) {
        setupPhysics()
        setupCamera()  // 카메라 먼저 설정
        setupPlayer()
        setupGround()
        setBricks()
    }

    /// 카메라 설정
    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)

        // 초기 카메라 위치
        gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    /// 중력 설정
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -GameConstant.gravity)
        physicsWorld.contactDelegate = self
    }
    
    /// 플레이어 생성 및 속성 설정
    private func setupPlayer() {
        player = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        player.position = CGPoint(x: size.width / 2, y: 200)
        player.name = "player"

        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true        // 중력/힘 영향 받음
        player.physicsBody?.categoryBitMask = 1     // 플레이어 카테고리
        player.physicsBody?.collisionBitMask = 6    // 홀수 벽돌(2) + 짝수 벽돌(4) = 6 (의도한대로 동작하지 않음)
        player.physicsBody?.restitution = GameConstant.playerRestitution       // 탄성 (약간 튕김)
        player.physicsBody?.friction = GameConstant.playerFriction
        player.physicsBody?.allowsRotation = false

        // 초기 최고 높이 설정
        maxPlayerY = player.position.y

        addChild(player)
    }
    
    /// 게임 바닥 구성
    private func setupGround() {
        let ground = SKSpriteNode(color: .green, size: CGSize(width: size.width, height: 50))
        ground.position = CGPoint(x: size.width / 2, y: 25)
        ground.name = "ground"

        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 2  // 벽돌과 같은 카테고리
        ground.physicsBody?.friction = 0.5

        addChild(ground)
    }
    
    private func setBricks() {
        for level in 0..<GameConstant.numberOfLevels {
            let y = GameConstant.startY + CGFloat(level) * GameConstant.verticalGap

            // 지그재그: 짝수는 왼쪽, 홀수는 오른쪽
            let x: CGFloat
            let isEven = level % 2 == 0
            if isEven {
                x = size.width * 0.25  // 왼쪽
            } else {
                x = size.width * 0.75  // 오른쪽
            }

            let brick = SKSpriteNode(color: .brown,
                                     size: CGSize(width: GameConstant.brickWidth,
                                                  height: GameConstant.brickHeight))
            brick.position = CGPoint(x: x, y: y)
            brick.name = "brick_\(level)"

            brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
            brick.physicsBody?.isDynamic = false

            // 짝수 벽돌과 홀수 벽돌을 다른 카테고리로 분리
            if isEven {
                brick.physicsBody?.categoryBitMask = 2  // 짝수 벽돌
            } else {
                brick.physicsBody?.categoryBitMask = 4  // 홀수 벽돌
            }

            // 플레이어(1)하고만 충돌, 서로는 충돌하지 않음
            brick.physicsBody?.collisionBitMask = 1
            brick.physicsBody?.friction = 0.0  // 마찰 없음 (옆면에 붙지 않도록)

            addChild(brick)
        }
    }
    
    /// 프레임마다 호출 (60fps)
    public override func update(_ currentTime: TimeInterval) {
        // 좌우 이동 처리
        if moveDirection != 0 {
            player.physicsBody?.velocity.dx = moveDirection * GameConstant.moveSpeed
        }

        // 화면 경계 벗어나지 않도록 제한 (카메라 기준)
        let halfWidth = player.size.width / 2
        let cameraX = gameCamera.position.x

        let leftBound = cameraX - size.width / 2 + halfWidth
        let rightBound = cameraX + size.width / 2 - halfWidth

        if player.position.x < leftBound {
            player.position.x = leftBound
            player.physicsBody?.velocity.dx = 0  // 벽에 닿으면 정지
        } else if player.position.x > rightBound {
            player.position.x = rightBound
            player.physicsBody?.velocity.dx = 0
        }

        // 카메라 추적
        updateCamera()
    }

    /// 카메라 업데이트 (플레이어 따라가기)
    private func updateCamera() {
        // 플레이어가 최고 높이를 갱신했는지 체크
        if player.position.y > maxPlayerY {
            maxPlayerY = player.position.y
        }

        // 카메라 목표 위치 계산
        // 플레이어가 화면 아래쪽 1/3 지점에 오도록
        let targetY = max(size.height / 2, maxPlayerY - size.height / 3)

        // 부드러운 카메라 이동 설정
        let lerpFactor: CGFloat = 0.1
        let newY = gameCamera.position.y + (targetY - gameCamera.position.y) * lerpFactor

        gameCamera.position.y = newY

        // X축은 화면 중앙 고정
        gameCamera.position.x = size.width / 2
    }
    
    /// 점프 시 동작 정의
    public func jump(isSuper: Bool = false) {
        // 바닥에 닿아있을 때만 점프 가능
        guard let velocity = player.physicsBody?.velocity,
              abs(velocity.dy) < 10 else { return }

        let impulse = isSuper ? GameConstant.superJumpImpulse : GameConstant.normalJumpImpulse
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: impulse))

        logger.info("\(isSuper ? "🚀 슈퍼점프" : "⬆️ 기본점프")")
    }

    /// 방향 정하기
    public func move(direction: CGFloat) {
        moveDirection = direction
    }
}

extension GameScene: SKPhysicsContactDelegate {
    /// 충돌 처리
    public func didBegin(_ contact: SKPhysicsContact) {
        logger.debug("💥 충돌 감지")        // 충돌 감지 시 파티클 튀기는 기능이 있다면 여기서 추가
    }
}
