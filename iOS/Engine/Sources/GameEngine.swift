//
//  GameScene.swift
//  Engine
//
//  Created by 강윤서 on 12/17/25.
//

import SpriteKit
import OSLog

public class GameScene: SKScene {
    
    private var player: SKSpriteNode!
    private var moveDirection: CGFloat = 0  /// -1(왼쪽), 0(정지), 1(오른쪽)
    private var logger = Logger()
    
    // 점프 속도
    private let normalJumpImpulse: CGFloat = 500
    private let superJumpImpulse: CGFloat = 800
    
    public override func didMove(to view: SKView) {
        setupPhysics()
        setupPlayer()
        setupGround()
    }
    
    /// 중력 설정
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }
    
    /// 플레이어 생성 및 속성 설정
    private func setupPlayer() {
        player = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        player.position = CGPoint(x: size.width / 2, y: 200)
        
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true        // 중력/힘 영향 받음
        player.physicsBody?.categoryBitMask = 1     // 충돌 카테고리
        player.physicsBody?.contactTestBitMask = 2  // 바닥과 충돌 감지
        player.physicsBody?.restitution = 0.2       // 탄성 (약간 튕김)
        player.physicsBody?.friction = 0.5
        
        addChild(player)
    }
    
    /// 게임 바닥 구성
    private func setupGround() {
        let ground = SKSpriteNode(color: .green, size: CGSize(width: size.width, height: 50))
        ground.position = CGPoint(x: size.width / 2, y: 25)
        
        // 바닥 물리 - 고정된 물체
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false  // 움직이지 않음
        ground.physicsBody?.categoryBitMask = 2
        
        addChild(ground)
    }
    
    /// 프레임마다 호출 (60fps)
    public override func update(_ currentTime: TimeInterval) {
        // 좌우 이동 처리
        if moveDirection != 0 {
            let moveSpeed: CGFloat = 300  // 초당 300포인트
            player.physicsBody?.velocity.dx = moveDirection * moveSpeed
        // 화면 경계 벗어나지 않도록 제한
        let halfWidth = player.size.width / 2
        if player.position.x < halfWidth {
            player.position.x = halfWidth
            player.physicsBody?.velocity.dx = 0  // 벽에 닿으면 정지
        } else if player.position.x > size.width - halfWidth {
            player.position.x = size.width - halfWidth
            player.physicsBody?.velocity.dx = 0
        }
    }
    
    /// 점프 시 동작 정의
    public func jump(isSuper: Bool = false) {
        // 바닥에 닿아있을 때만 점프 가능
        guard let velocity = player.physicsBody?.velocity,
              abs(velocity.dy) < 10 else { return }
        
        let impulse = isSuper ? superJumpImpulse : normalJumpImpulse
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
        print("💥 Collision detected")
    }
}
