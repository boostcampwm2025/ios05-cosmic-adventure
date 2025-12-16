//
//  CosmicGameScene.swift
//  iOS
//
//  Created by soyoung on 12/16/25.
//

import SwiftUI
import SpriteKit

// 발판 클래스
class PlatformNode: SKSpriteNode {
    init(position: CGPoint) {
        // 발판 크기: 너비 100, 높이 20
        let size = CGSize(width: 100, height: 20)
        // 텍스처가 있다면 texture: SKTexture(imageNamed: "Platform") 등으로 변경 가능
        super.init(texture: nil, color: .brown, size: size)

        self.position = position
        self.name = "platform"

        // 물리 설정: 고정된 물체
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = 2       // 카테고리 2: 발판
        self.physicsBody?.friction = 1.0            // 미끄러짐 방지
        self.physicsBody?.restitution = 0.0         // 통통 튀김 방지
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CosmicGameScene: SKScene, SKPhysicsContactDelegate {
    private var player: SKSpriteNode!
    private var statusLabel: SKLabelNode!

    // 카메라
    private var cameraNode: SKCameraNode!

    // 계단(발판) 관리 변수
    private var platforms: [PlatformNode] = []
    private var lastPlatformPos: CGPoint = CGPoint(x: 0, y: -100) // 시작 위치
    private var isNextRight: Bool = true // 다음 발판이 오른쪽인지 여부 (지그재그용)

    // [공기팡] 차징 관련 변수
    private var currentCharge: Double = 0.0
    private var isCharging: Bool = false
    private let chargeSpeed: Double = 0.02

    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        view.allowsTransparency = true
        view.backgroundColor = .clear

        // 1. 물리 세계 설정
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        self.physicsWorld.contactDelegate = self

        // 2. 카메라 설정
        cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)

        // 3. 요소 배치
        setupBackground()
        setupPlayer()
        setupUI()

        // 4. 초기 계단 생성 (지그재그)
        spawnInitialStairs()
    }

    // 초기 계단 배치
    func spawnInitialStairs() {
        // 시작점 초기화
        lastPlatformPos = CGPoint(x: 0, y: -100)
        isNextRight = true // 처음엔 오른쪽으로 시작

        for _ in 0..<10 {
            spawnNextStep()
        }
    }

    // 다음 계단 생성 (지그재그 패턴)
    func spawnNextStep() {
        // 1. Y축: 위로 120만큼 이동
        let nextY = lastPlatformPos.y + 120

        // 2. X축: 지그재그 로직 (오른쪽 -> 왼쪽 -> 오른쪽 ...)
        // 중앙(0)을 기준으로 오른쪽(+80)과 왼쪽(-80)을 왔다갔다 함
        let nextX: CGFloat = isNextRight ? 80 : -80

        let nextPos = CGPoint(x: nextX, y: nextY)

        // 3. 발판 생성
        let newPlatform = PlatformNode(position: nextPos)
        addChild(newPlatform)
        platforms.append(newPlatform)

        // 4. 상태 업데이트
        lastPlatformPos = nextPos
        isNextRight.toggle() // 방향 반전 (True -> False -> True)

        // 5. 청소
        cleanUpOldPlatforms()
    }

    // 지나간 발판 삭제
    func cleanUpOldPlatforms() {
        let lowerBound = cameraNode.position.y - 800
        platforms.removeAll { platform in
            if platform.position.y < lowerBound {
                platform.removeFromParent()
                return true
            }
            return false
        }
    }

    // 매 프레임 실행
    override func update(_ currentTime: TimeInterval) {
        // 1. 카메라 추적 (부드럽게 따라가기)
        // 플레이어보다 카메라가 낮으면 따라 올라감
        if player.position.y > cameraNode.position.y {
            let lerpY = cameraNode.position.y + (player.position.y - cameraNode.position.y) * 0.1
            cameraNode.position.y = lerpY

            // UI도 같이 이동
            statusLabel.position.y = cameraNode.position.y + 300
        }

        // 2. 무한 생성: 맨 위 발판이 보일 때쯤 새거 추가
        if lastPlatformPos.y < cameraNode.position.y + 500 {
            spawnNextStep()
        }

        // 3. 게임 오버 체크 (떨어짐)
        if player.position.y < cameraNode.position.y - 600 {
            print("💀 떨어짐!")
            resetGame()
        }
    }

    func resetGame() {
        player.position = CGPoint(x: 0, y: 0)
        player.physicsBody?.velocity = .zero
        cameraNode.position = .zero

        platforms.forEach { $0.removeFromParent() }
        platforms.removeAll()

        spawnInitialStairs()
        statusLabel.position = CGPoint(x: 0, y: 300)
        statusLabel.text = "다시 시작!"
    }

    // 입력 처리
    func updateInput(pucker: Float, puff: Float, jawOpen: Float, roll: Float) {
        // [수정] 갸웃거림(Roll)은 이제 미세 조정용으로만 씁니다. (자동 점프가 되므로)
        updateMovement(roll: roll)

        if puff > 0.4 {
            startCharging()
            statusLabel.text = "기 모으는 중... 😡"
            return
        }

        if isCharging && puff < 0.15 {
            fireAirPang()
            return
        }

        if !isCharging {
            if pucker > 0.4 && jawOpen < 0.2 {
                jumpToNextPlatform() // ✨ 포물선 점프 함수 호출
            }
        }
    }

    // 미세 이동 (선택 사항)
    private func updateMovement(roll: Float) {
        let deadZone: Float = 0.05
        let moveSpeed: CGFloat = 300.0 // 속도를 좀 줄임 (점프가 메인이라)

        if abs(roll) > deadZone {
            let velocityX = CGFloat(roll) * moveSpeed
            if let currentDy = player.physicsBody?.velocity.dy {
                player.physicsBody?.velocity = CGVector(dx: velocityX, dy: currentDy)
            }
        }
    }

    private func startCharging() {
        isCharging = true
        if currentCharge < 1.0 { currentCharge += chargeSpeed }
        player.color = .red
        player.colorBlendFactor = CGFloat(currentCharge)
    }

    private func fireAirPang() {
        // 공기팡은 수직으로 강력하게!
        let minForce: Double = 100.0
        let maxBonusForce: Double = 300.0
        let totalForce = minForce + (maxBonusForce * currentCharge)

        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: totalForce))

        statusLabel.text = "공기팡 발사!! 💨"
        resetCharge()
    }

    // 지그재그 포물선 점프
    private func jumpToNextPlatform() {
        guard let dy = player.physicsBody?.velocity.dy, abs(dy) < 1.0 else { return }

        // 1. 현재 내 위치 파악
        let currentX = player.position.x

        // 2. 점프 방향 결정 (포물선 만들기)
        // 내가 왼쪽에 있으면(-80 근처) -> 오른쪽으로 점프해야 함 (+힘)
        // 내가 오른쪽에 있으면(+80 근처) -> 왼쪽으로 점프해야 함 (-힘)
        // 중앙이면(0) -> 지그재그 순서에 맞게 감

        var jumpDx: CGFloat = 0

        if currentX < -20 { // 왼쪽에 있음
            jumpDx = 180 // 오른쪽으로 뛴다
            player.xScale = 1 // 오른쪽 보기 (Alien 원본 방향)
        } else if currentX > 20 { // 오른쪽에 있음
            jumpDx = -180 // 왼쪽으로 뛴다
            player.xScale = -1 // 왼쪽 보기 (이미지 반전)
        } else {
            // 중앙에 있으면 랜덤 혹은 오른쪽
             jumpDx = 180
             player.xScale = 1
        }

        // 3. 포물선 힘 적용 (대각선 점프)
        // dx: 가로 이동 힘, dy: 높이 점프 힘
        player.physicsBody?.applyImpulse(CGVector(dx: jumpDx, dy: 550))

        statusLabel.text = "폴짝!"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusLabel.text = ""
        }
    }

    private func resetCharge() {
        isCharging = false
        currentCharge = 0.0
        let colorAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
        player.run(colorAction)
    }

    private func setupBackground() {
        let ground = SKSpriteNode(color: .darkGray, size: CGSize(width: 200, height: 20))
        ground.position = CGPoint(x: 0, y: -150)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 2
        addChild(ground)
    }

    private func setupPlayer() {
        // 캐릭터 이미지 사용
        let texture = SKTexture(imageNamed: "Alien")
        player = SKSpriteNode(texture: texture)

        // 비율 유지하며 크기 조절
        let ratio = texture.size().width / texture.size().height
        let height: CGFloat = 70 // 크기 살짝 줄임 (발판에 맞게)
        player.size = CGSize(width: height * ratio, height: height)

        player.position = CGPoint(x: 0, y: 0)

        // 물리 설정
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.height / 2.5)
        player.physicsBody?.allowsRotation = false // 회전 금지 (서있는 상태 유지)
        player.physicsBody?.restitution = 0.0

        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.collisionBitMask = 2
        player.physicsBody?.contactTestBitMask = 2

        addChild(player)
    }

    private func setupUI() {
        statusLabel = SKLabelNode(text: "준비 완료")
        statusLabel.fontSize = 24
        statusLabel.position = CGPoint(x: 0, y: 300)
        addChild(statusLabel)
    }
}
