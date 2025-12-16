//
//  CosmicGameScene.swift
//  iOS
//
//  Created by soyoung on 12/16/25.
//

import SwiftUI
import SpriteKit

class CosmicGameScene: SKScene {
    private var player: SKSpriteNode!
    private var statusLabel: SKLabelNode!

    // [공기팡] 차징 관련 변수
    private var currentCharge: Double = 0.0      // 현재 모인 힘 (0.0 ~ 1.0)
    private var isCharging: Bool = false         // 지금 기를 모으는 중인가?
    private let chargeSpeed: Double = 0.02       // 기가 모이는 속도

    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        view.allowsTransparency = true
        view.backgroundColor = .clear

        setupPhysics()
        setupBackground()
        setupPlayer()
        setupUI()
    }

    // ContentView에서 매 프레임 호출하는 입력 관리 함수
    func updateInput(pucker: Float, puff: Float, jawOpen: Float, roll: Float) {
        // [좌우 이동 로직] (갸웃갸웃)
        updateMovement(roll: roll)

        // 1. [우선순위 1위] 차징 시작 & 진행 (볼 빵빵 0.4 이상) -> '우'를 있는 힘껏 해보니 0.4보다 살짝 떨어지는 정도
        if puff > 0.4 {
            startCharging()
            statusLabel.text = "기 모으는 중... 😡"
            return // 차징 중에는 아래 '우~' 로직 실행 금지
        }

        // 2. [우선순위 2위] 공기팡 발사! (차징 중이었다가 볼 바람이 빠짐)
        if isCharging && puff < 0.15 {
            fireAirPang()
            return
        }

        // 3. [우선순위 3위] 기본 점프 (우~)
        // 차징 중이 아닐 때만 작동
        if !isCharging {
            // "우~"는 0.4 이상, "아~"는 아니어야 함 (정확도 향상)
            if pucker > 0.4 && jawOpen < 0.2 {
                jump()
            }
        }
    }

    // 좌우 이동 처리 함수
    private func updateMovement(roll: Float) {
        // roll 값은 보통 -0.5 ~ 0.5 (라디안) 사이로 들어옵니다.
        // 중앙(0.0)에 있을 때 미세한 떨림을 막기 위해 데드존(Deadzone)을 둡니다.

        let deadZone: Float = 0.05 // 갸웃 각도가 이보다 작으면 움직이지 않음
        let moveSpeed: CGFloat = 500.0 // 이동 속도 (조절 가능)

        if abs(roll) > deadZone {
            // 각도에 비례해서 속도를 줍니다 (많이 기울이면 빨리 감)
            let velocityX = CGFloat(roll) * moveSpeed

            // 기존의 점프 속도(dy)는 유지하고, 좌우 속도(dx)만 바꿉니다.
            if let currentDy = player.physicsBody?.velocity.dy {
                player.physicsBody?.velocity = CGVector(dx: velocityX, dy: currentDy)
            }
        } else {
            // 머리를 똑바로 하면 좌우 멈춤 (마찰력 느낌)
            if let currentDy = player.physicsBody?.velocity.dy {
                // 서서히 멈추게 하려면 dx에 0.9 등을 곱해주면 됨. 지금은 즉시 정지.
                player.physicsBody?.velocity = CGVector(dx: 0, dy: currentDy)
            }
        }
    }

    // 기 모으기
    private func startCharging() {
        isCharging = true

        // 힘을 최대 1.0까지만 모음
        if currentCharge < 1.0 {
            currentCharge += chargeSpeed
        }

        // 시각 효과: 힘을 모을수록 캐릭터가 빨개짐
        player.color = .red
        player.colorBlendFactor = CGFloat(currentCharge)
    }

    // 공기팡 발사 (강력한 점프)
    private func fireAirPang() {
        // 최소 힘(300) + 모은 힘(최대 700) = 최대 1000
        let minForce: Double = 300.0
        let maxBonusForce: Double = 700.0
        let totalForce = minForce + (maxBonusForce * currentCharge)

        // 기존 속도 제거 후 발사 (더 팍! 튀어오르는 느낌)
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: totalForce))

        statusLabel.text = "공기팡 발사!! 💨"

        // 상태 초기화
        resetCharge()
    }

    // 기본 점프 (우~)
    private func jump() {
        // 땅에 있을 때만 점프 (연타 방지)
        guard let dy = player.physicsBody?.velocity.dy, abs(dy) < 1.0 else {
            return
        }

        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 350)) // 가볍게 350
        statusLabel.text = "폴짝! (기본 점프)"

        // 텍스트 복귀
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusLabel.text = "준비 완료"
        }
    }

    // 상태 초기화
    private func resetCharge() {
        isCharging = false
        currentCharge = 0.0

        // 색깔 원래대로 복구 애니메이션
        let colorAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
        player.run(colorAction)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.statusLabel.text = "준비 완료"
        }
    }

    private func setupPhysics() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    }

    private func setupBackground() {
        let ground = SKSpriteNode(color: .black, size: CGSize(width: self.size.width, height: 50))
        ground.position = CGPoint(x: self.size.width / 2, y: 25)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        addChild(ground)
    }

    private func setupPlayer() {
        player = SKSpriteNode(color: .systemGreen, size: CGSize(width: 60, height: 60))
        player.position = CGPoint(x: self.size.width / 2, y: 100)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 0.0
        addChild(player)
    }

    private func setupUI() {
        statusLabel = SKLabelNode(text: "우~(점프) 또는 볼빵빵(차징)")
        statusLabel.fontSize = 24
        statusLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 100)
        addChild(statusLabel)
    }
}
