//
//  PlatformController.swift
//  App
//
//  Created by 영빈 on 1/8/26.
//

import SpriteKit

final class PlatformController {
    private weak var scene: SKScene?
    
    private var lastPlatformY: CGFloat = -100
    private var isNextRight: Bool = true
    private let xOffset: CGFloat = 70
    private let yGap: CGFloat = 130
    
    // Platform indexing
    private var nextPlatformIndex: Int = 0
    private var platformNodesByIndex: [Int: SKSpriteNode] = [:]

    // Player가 마지막으로 밟은(안전) 플랫폼
    private(set) var lastSafePosition: CGPoint = CGPoint(x: 0, y: -150)
    private(set) var lastSafePlatformIndex: Int = 0
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupInitialPlatforms() {
        guard let scene else { return }
        
        let startY: CGFloat = -200
        let startPlatform = createPlatform(
            index: allocateIndex(),
            position: CGPoint(x: 0, y: startY),
            size: CGSize(width: 200, height: 35)
        )
        register(platform: startPlatform)
        scene.addChild(startPlatform)
        
        // 시작 플랫폼은 즉시 충돌 가능하도록 선활성
        startPlatform.physicsBody?.categoryBitMask = PhysicsCategory([.groundMe, .groundOther]).rawValue
        
        lastSafePosition = startPlatform.position
        lastSafePlatformIndex = platformIndex(for: startPlatform) ?? 0
        lastPlatformY = startY
        
        for _ in 0..<10 {
            spawnNextPlatform()
        }
        
        // 초기 상태: GameScene가 플레이어 bottomY를 넘겨주기 전까지 플랫폼 충돌을 비활성화
        applyLocalTransparency()
    }
    
    /// 플랫폼 생성 및 제거 업데이트
    /// - Parameters:
    ///   - requiredTopY: 플랫폼이 미리 생성되어 있어야 하는 최상단 월드 Y값 (예: 두 플레이어 Y 중 최대값)
    ///   - cullBelowY: 이 값보다 충분히 아래(버퍼 포함)는 플랫폼을 제거해도 되는 기준 Y값 (예: 두 플레이어 Y 중 최소값)
    func update(requiredTopY: CGFloat, cullBelowY: CGFloat) {
        guard let scene else { return }

        let sceneHeight = scene.size.height

        // requiredTopY보다 위쪽까지 미리(prefetch) 플랫폼을 생성
        let prefetchMargin: CGFloat = sceneHeight
        while lastPlatformY < requiredTopY + prefetchMargin {
            spawnNextPlatform()
        }

        // 보수적으로(충분한 버퍼를 두고) 컬링
        let deleteBuffer: CGFloat = sceneHeight * 2
        let cullLineY = cullBelowY - deleteBuffer

        scene.enumerateChildNodes(withName: L10N.Game.NodeName.platform) { [weak self] node, _ in
            guard let self else { return }

            // 가장 아래 플레이어 기준선보다 훨씬 아래에 있고,
            // 또한 로컬 lastSafePosition(안전 지점)보다 아래에 있는 플랫폼만 제거
            // (멀티플레이에서 한쪽이 아직 필요로 하는 플랫폼을 실수로 삭제하는 것을 방지)
            if node.position.y < cullLineY && node.position.y < self.lastSafePosition.y {
                if let idx = self.platformIndex(for: node) {
                    self.platformNodesByIndex[idx] = nil
                }
                node.removeFromParent()
            }
        }
    }
    
    func updateLastSafePlatform(_ platformNode: SKNode) {
        lastSafePosition = platformNode.position
        if let idx = platformIndex(for: platformNode) {
            lastSafePlatformIndex = idx
        }
        applyLocalTransparency()
    }
    
    /// 세이프 포지션(마지막으로 밟은 플랫폼)의 topY(frame.maxY)
    func safePlatformTopY() -> CGFloat? {
        guard let node = platformNodesByIndex[lastSafePlatformIndex] else { return nil }
        guard node.parent != nil else { return nil }
        return node.frame.maxY
    }
    
    private func spawnNextPlatform() {
        guard let scene else { return }
        
        let nextY = lastPlatformY + yGap
        let nextX: CGFloat = isNextRight ? xOffset : -xOffset
        
        let platform = createPlatform(index: allocateIndex(), position: CGPoint(x: nextX, y: nextY))
        register(platform: platform)
        scene.addChild(platform)
        
        lastPlatformY = nextY
        isNextRight.toggle()
        
        applyLocalTransparency()
    }
    
    private func createPlatform(index: Int, position: CGPoint, size: CGSize = CGSize(width: 110, height: 35)) -> SKSpriteNode {
        let platform = SKSpriteNode(imageNamed: AppAsset.Image.platform.name)
        platform.name = L10N.Game.NodeName.platform
        platform.size = size
        platform.position = position

        // index 저장
        if platform.userData == nil { platform.userData = [:] }
        platform.userData?["platformIndex"] = index

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false

        body.categoryBitMask = 0
        body.restitution = 0.0
        body.friction = 1.0    // 미끄러짐 방지

        let collidesWith: PhysicsCategory = [.playerMe, .playerOther]
        body.collisionBitMask = collidesWith.rawValue
        // 플랫폼은 충돌만 담당. 접촉 이벤트는 플레이어 쪽 contactTest로 충분.
        body.contactTestBitMask = 0

        platform.physicsBody = body
        return platform
    }
    
    private func allocateIndex() -> Int {
        defer { nextPlatformIndex += 1 }
        return nextPlatformIndex
    }

    private func register(platform: SKSpriteNode) {
        if let idx = platformIndex(for: platform) {
            platformNodesByIndex[idx] = platform
        }
    }

    private func platformIndex(for node: SKNode) -> Int? {
        if let n = node.userData?["platformIndex"] as? Int { return n }
        if let n = node.userData?["platformIndex"] as? NSNumber { return n.intValue }
        return nil
    }
    
    // MARK: - Collision + transparency

    /// 각 플레이어의 위치(bottomY)와 낙하 속도(dy)를 이용해 플랫폼 충돌 카테고리를 갱신
    /// - NOTE: 빠른 낙하 시 한 프레임 사이에 bottomY가 크게 변할 수 있어 dy*dt 기반 버퍼를 둔다.
    ///         buffer = min(120, 10 + |dy| * dt)  (dy < 0일 때만 유의미하게 커짐)
    func updateCollisions(
        localBottomY: CGFloat?,
        localDY: CGFloat?,
        otherBottomY: CGFloat?,
        otherDY: CGFloat?,
        deltaTime: TimeInterval
    ) {
        applyCollisionCategories(
            localBottomY: localBottomY,
            localDY: localDY,
            otherBottomY: otherBottomY,
            otherDY: otherDY,
            deltaTime: deltaTime
        )
        applyLocalTransparency()
    }
    
    private func fallBuffer(dy: CGFloat?, dt: TimeInterval) -> CGFloat {
        let base: CGFloat = 10
        guard let dy else { return base }
        // dy < 0(낙하)일 때만 버퍼를 크게(빠른 낙하 랜딩 누락 방지)
        let extra = dy < 0 ? (-dy) * CGFloat(dt) : 0
        return min(120, base + extra)
    }
    
    private func applyCollisionCategories(
        localBottomY: CGFloat?,
        localDY: CGFloat?,
        otherBottomY: CGFloat?,
        otherDY: CGFloat?,
        deltaTime: TimeInterval
    ) {

        for (_, node) in platformNodesByIndex {
            guard node.parent != nil, let body = node.physicsBody else { continue }

            let topY = node.frame.maxY
            var category: PhysicsCategory = []

            if let localBottomY {
                let buffer = fallBuffer(dy: localDY, dt: deltaTime)
                if topY <= localBottomY + buffer {
                    category.insert(.groundMe)
                }
            }

            if let otherBottomY {
                let buffer = fallBuffer(dy: otherDY, dt: deltaTime)
                if topY <= otherBottomY + buffer {
                    category.insert(.groundOther)
                }
            }

            body.categoryBitMask = category.rawValue
        }
    }

    private func applyLocalTransparency() {
        let current = lastSafePlatformIndex
        let prev = max(0, current - 1)
        let next = current + 1

        for (idx, node) in platformNodesByIndex {
            guard node.parent != nil else { continue }
            if idx == prev || idx == current || idx == next {
                node.alpha = 1.0
            } else {
                node.alpha = 0.5
            }
        }
    }
}
