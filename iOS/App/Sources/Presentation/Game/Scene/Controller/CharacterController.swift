//
//  CharacterController.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/12/26.
//

import Games
import GameEngineCore
import SpriteKit

final class CharacterController {
    private weak var scene: SKScene?
    private let cameraSystem: CameraSystem
    
    let playerRole: GamePlayerRole

    private(set) var playerNode: SKSpriteNode?
    private(set) var physicsCore: PhysicsCore?

    private var sceneSize: CGSize { scene?.size ?? .zero }
    
    // 리스폰 표시
    private var respawnLabel: SKLabelNode?
    private var storedMasks: (category: UInt32, contact: UInt32, collision: UInt32)?
    
    // 최소 정보만 노출
    var positionY: CGFloat? { playerNode?.position.y }
    var bottomY: CGFloat? {
        guard let node = playerNode else { return nil }
        return node.position.y - (node.size.height / 2)
    }
    var velocityDY: CGFloat { playerNode?.physicsBody?.velocity.dy ?? 0 }
    
    init(scene: SKScene, cameraSystem: CameraSystem, playerRole: GamePlayerRole = .local) {
        self.scene = scene
        self.cameraSystem = cameraSystem
        self.playerRole = playerRole
    }
    
    func setupPlayer(
        initialPosition: CGPoint = CGPoint(x: 0, y: -50),
        size: CGSize = CGSize(width: 50, height: 60),
        characterType: CharacterAvatar
    ) {
        if playerNode != nil { return }
        guard let scene else { return }
        
        let player = SKSpriteNode(imageNamed: characterType.name)
        player.name = "\(L10N.Game.NodeName.player)_\(playerRole.rawValue)"
        player.size = size
        player.position = initialPosition
        
        if playerRole == .remote {
            player.alpha = 0.4
        }
        
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.allowsRotation = false
        
        if playerRole == .local {
            body.categoryBitMask = PhysicsCategory.playerMe.rawValue
            
            let collidesWith: PhysicsCategory = [.groundMe, .wall]
            body.collisionBitMask = collidesWith.rawValue
            
            let contactsWith: PhysicsCategory = [.groundMe, .monster]
            body.contactTestBitMask = contactsWith.rawValue
        } else {
            body.categoryBitMask = PhysicsCategory.playerOther.rawValue

            let collidesWith: PhysicsCategory = [.groundOther, .wall]
            body.collisionBitMask = collidesWith.rawValue

            let contactsWith: PhysicsCategory = [.groundOther]
            body.contactTestBitMask = contactsWith.rawValue
        }
        
        body.velocity = .zero
        player.physicsBody = body
        
        scene.addChild(player)
        self.playerNode = player
        
        // 커스텀 물리 엔진 연결
        if let playerBody = player.physicsBody {
            physicsCore = PhysicsCore(body: playerBody)
            playerBody.usesPreciseCollisionDetection = true
        }
    }

    func isBelow(cameraBottom: CGFloat, margin: CGFloat) -> Bool {
        guard let y = positionY else { return false }
        return y < cameraBottom - margin
    }

    func freezePhysics() {
        guard let body = playerNode?.physicsBody else { return }
        body.velocity = .zero
        body.isDynamic = false
    }

    func resumePhysics() {
        playerNode?.physicsBody?.isDynamic = true
    }
    
    func setupHUD() {
        guard respawnLabel == nil, let scene else { return }
        let label = SKLabelNode(fontNamed: AppFontFamily.Pretendard.bold.name)
        label.fontSize = 24
        label.fontColor = AppAsset.Color.mainLabel.color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 10_000
        label.alpha = 0
        
        label.position = CGPoint(x: 0, y: (playerNode?.size.height ?? 60) + 20)
        
        // 플레이어 위에 보이도록 위치 동기화
        syncRespawnLabelPosition(label: label)

        // playerNode의 alpha 영향을 받지 않도록 scene에 붙인다
        scene.addChild(label)
        respawnLabel = label
    }
    
    private func syncRespawnLabelPosition(label: SKLabelNode? = nil) {
        guard let playerNode else { return }
        let label = label ?? respawnLabel
        guard let label else { return }

        // 캐릭터 상단 중앙에 고정
        let yOffset = (playerNode.size.height / 2) + 24
        label.position = CGPoint(x: playerNode.position.x, y: playerNode.position.y + yOffset)
    }
    
    func applyMovement(deltaTime: TimeInterval,
                       moveX: Double,
                       isGrounded: Bool
    ) {
        guard let physicsCore else { return }
        
        physicsCore.applyState(deltaTime: deltaTime, moveX: moveX, isGrounded: isGrounded)
        
        animatePlayer(moveX: moveX)
        syncRespawnLabelPosition()
    }
    
    // TODO: 애니메이션 분기 처리
    
    func animatePlayer(moveX: Double) {
        guard let playerNode else { return }
        // 좌우 반전
        if moveX < -0.01 {
            // 왼쪽 이동
            playerNode.xScale = abs(playerNode.xScale)
        } else if moveX > 0.01 {
            // 오른쪽 이동
            playerNode.xScale = -abs(playerNode.xScale)
        }
        // TODO: 애니메이션 적용
    }
    
    func applyJump() {
        guard let physicsCore else { return }
        physicsCore.applyJumpImpulse()
    }
}

// MARK: 리스폰 관리

extension CharacterController {
    func moveToRespawn(lastSafePosition: CGPoint, playerYOffset: CGFloat = 100, cameraYOffset: CGFloat = 200) {
        guard let playerNode else { return }
        let base = (lastSafePosition == .zero) ? CGPoint(x: 0, y: -100) : lastSafePosition
        playerNode.position = CGPoint(x: base.x, y: base.y + playerYOffset)

        syncRespawnLabelPosition()
    }
    
    func beginRespawn(reason: RespawnReason, duration: TimeInterval) {
        guard let playerNode else { return }

        // 반투명(로컬만 투명도 적용)
        if playerRole == .local {
            playerNode.alpha = 0.25
        }
        
        // 리스폰 중 충돌/접촉 방지 (무적)
        if storedMasks == nil, let body = playerNode.physicsBody {
            storedMasks = (body.categoryBitMask,
                           body.contactTestBitMask,
                           body.collisionBitMask)
        }
        if let body = playerNode.physicsBody {
            body.categoryBitMask = 0
            body.contactTestBitMask = 0
            body.collisionBitMask = 0
        }
        
        syncRespawnLabelPosition()
        showRespawnLabel(reason: reason, duration: duration)
    }

    func endRespawn() {
        guard let playerNode else { return }

        // 투명도 복구(로컬만 투명도 복구)
        if playerRole == .local {
            playerNode.alpha = 1.0
        }

        // 마스크 복구
        if let stored = storedMasks, let body = playerNode.physicsBody {
            body.categoryBitMask = stored.category
            body.contactTestBitMask = stored.contact
            body.collisionBitMask = stored.collision
        }
        storedMasks = nil

        hideRespawnLabel()
    }

    private func showRespawnLabel(reason: RespawnReason, duration: TimeInterval) {
        setupHUD()
        guard let label = respawnLabel else { return }

        label.removeAllActions()
        label.alpha = 1

        // duration이 0이면 짧게 로딩 느낌만
        let displayDuration = max(duration, 0.4)

        let update = SKAction.customAction(withDuration: displayDuration) { node, elapsed in
            guard let label = node as? SKLabelNode else { return }
            if duration >= 1 {
                let remaining = Int(ceil(displayDuration - elapsed))
                label.text = "\(remaining)"
            } else {
                label.text = "리스폰 중…"
            }
        }

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        label.run(.sequence([update, fadeOut]))
    }

    private func hideRespawnLabel() {
        guard let label = respawnLabel else { return }
        label.removeAllActions()
        label.alpha = 0
    }
}
