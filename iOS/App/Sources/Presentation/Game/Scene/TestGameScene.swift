//
//  TestGameScene.swift
//  App
//
//  Created by 영빈 on 1/28/26.
//

import Games
import GameEngineCore
import SpriteKit

final class TestGameScene: SKScene {
    
    private let inputProvider: FaceTrackingGameInputProvider
    private var inputTask: Task<Void, Never>?
    
    private var moveX: Double = 0.0
    private var isGrounded: Bool = false
    private var jumpCount: Int = 0
    private let maxJumpCount: Int = 2
    
    private var cameraSystem: CameraSystem?
    private var characterController: CharacterController?
    private var platforms: [SKSpriteNode] = []
    private var groundSegments: [SKSpriteNode] = []
    
    private var lastUpdateTime: TimeInterval = 0
    
    private let groundY: CGFloat = -200
    private let groundSegmentWidth: CGFloat = 800
    private let platformSize = CGSize(width: 150, height: 25)
    private let platformSpacingX: CGFloat = 250
    
    private var lastGeneratedPlatformX: CGFloat = 0
    private var firstGeneratedPlatformX: CGFloat = 0
    private var lastGeneratedGroundX: CGFloat = 0
    private var firstGeneratedGroundX: CGFloat = 0
    
    init(size: CGSize, inputProvider: FaceTrackingGameInputProvider) {
        self.inputProvider = inputProvider
        super.init(size: size)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: PhysicsConstants.gravityDY)
        self.physicsWorld.contactDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .clear
        
        setupInitialGround()
        setupInitialPlatforms()
        setupPlayer()
        startInputHandling()
    }
    
    override func willMove(from view: SKView) {
        inputTask?.cancel()
        inputTask = nil
    }
    
    private func setupInitialGround() {
        for i in -2...2 {
            let x = CGFloat(i) * groundSegmentWidth
            let segment = createGroundSegment(atX: x)
            addChild(segment)
            groundSegments.append(segment)
        }
        firstGeneratedGroundX = -2 * groundSegmentWidth
        lastGeneratedGroundX = 2 * groundSegmentWidth
    }
    
    private func createGroundSegment(atX x: CGFloat) -> SKSpriteNode {
        let segment = SKSpriteNode(color: .gray, size: CGSize(width: groundSegmentWidth, height: 50))
        segment.name = "ground_\(Int(x))"
        segment.position = CGPoint(x: x, y: groundY)
        
        let halfWidth = groundSegmentWidth / 2
        let halfHeight: CGFloat = 25
        let topLeft = CGPoint(x: -halfWidth, y: halfHeight)
        let topRight = CGPoint(x: halfWidth, y: halfHeight)
        
        let body = SKPhysicsBody(edgeFrom: topLeft, to: topRight)
        body.restitution = 0.0
        body.friction = 1.0
        body.categoryBitMask = PhysicsCategory.groundMe.rawValue
        body.collisionBitMask = PhysicsCategory.playerMe.rawValue
        body.contactTestBitMask = PhysicsCategory.playerMe.rawValue
        segment.physicsBody = body
        
        return segment
    }
    
    private func setupInitialPlatforms() {
        for i in -4...10 {
            let x = CGFloat(i) * platformSpacingX
            generatePlatformAt(x: x)
        }
        firstGeneratedPlatformX = -4 * platformSpacingX
        lastGeneratedPlatformX = 10 * platformSpacingX
    }
    
    private func generatePlatformAt(x: CGFloat) {
        let yOffset = CGFloat.random(in: 80...200)
        let platform = SKSpriteNode(imageNamed: AppAsset.Image.platform.name)
        platform.size = platformSize
        platform.position = CGPoint(x: x, y: groundY + yOffset)
        platform.name = "platform_\(Int(x))"
        
        let halfWidth = platformSize.width / 2
        let halfHeight = platformSize.height / 2
        let topLeft = CGPoint(x: -halfWidth, y: halfHeight)
        let topRight = CGPoint(x: halfWidth, y: halfHeight)
        
        let body = SKPhysicsBody(edgeFrom: topLeft, to: topRight)
        body.restitution = 0.0
        body.friction = 1.0
        body.categoryBitMask = PhysicsCategory.groundMe.rawValue
        body.collisionBitMask = PhysicsCategory.playerMe.rawValue
        body.contactTestBitMask = PhysicsCategory.playerMe.rawValue
        platform.physicsBody = body
        
        addChild(platform)
        platforms.append(platform)
    }
    
    private func setupPlayer() {
        let camSystem = CameraSystem(scene: self, smoothing: 0.1)
        self.cameraSystem = camSystem
        
        let controller = CharacterController(
            scene: self,
            cameraSystem: camSystem,
            playerRole: .local
        )
        controller.setupPlayer(
            initialPosition: CGPoint(x: 0, y: groundY + 80),
            size: CGSize(width: 50, height: 60),
            characterType: .character1
        )
        
        self.characterController = controller
    }
    
    private func startInputHandling() {
        inputTask = Task { [weak self] in
            guard let self else { return }
            let events = await self.inputProvider.events()
            
            for await event in events {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self.handleInputEvent(event)
                }
            }
        }
    }
    
    private func handleInputEvent(_ event: GameInputEvent) {
        switch event {
        case .horizontal(let x):
            moveX = x
            
        case .jump:
            if jumpCount < maxJumpCount {
                characterController?.applyJump()
                jumpCount += 1
                isGrounded = false
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        characterController?.applyMovement(
            deltaTime: deltaTime,
            moveX: moveX,
            isGrounded: isGrounded
        )
        
        updateCamera()
        generateContentIfNeeded()
        removeOffscreenContent()
    }
    
    private func updateCamera() {
        guard let cam = cameraSystem?.cameraNode,
              let playerNode = characterController?.playerNode else {
            return
        }
        
        let yOffset: CGFloat = 100.0
        let smoothing: CGFloat = 0.1
        
        let targetX = playerNode.position.x
        let targetY = playerNode.position.y + yOffset
        let newX = CGFloat.lerp(start: cam.position.x, end: targetX, t: smoothing)
        let newY = CGFloat.lerp(start: cam.position.y, end: targetY, t: smoothing)
        
        cam.position = CGPoint(x: newX, y: newY)
    }
    
    private func generateContentIfNeeded() {
        guard let cam = cameraSystem?.cameraNode else { return }
        let screenWidth = size.width
        let buffer = screenWidth * 1.5
        
        let rightEdge = cam.position.x + buffer
        let leftEdge = cam.position.x - buffer
        
        while lastGeneratedGroundX < rightEdge {
            lastGeneratedGroundX += groundSegmentWidth
            let segment = createGroundSegment(atX: lastGeneratedGroundX)
            addChild(segment)
            groundSegments.append(segment)
        }
        
        while firstGeneratedGroundX > leftEdge {
            firstGeneratedGroundX -= groundSegmentWidth
            let segment = createGroundSegment(atX: firstGeneratedGroundX)
            addChild(segment)
            groundSegments.insert(segment, at: 0)
        }
        
        while lastGeneratedPlatformX < rightEdge {
            lastGeneratedPlatformX += platformSpacingX
            generatePlatformAt(x: lastGeneratedPlatformX)
        }
        
        while firstGeneratedPlatformX > leftEdge {
            firstGeneratedPlatformX -= platformSpacingX
            generatePlatformAt(x: firstGeneratedPlatformX)
        }
    }
    
    private func removeOffscreenContent() {
        guard let cam = cameraSystem?.cameraNode else { return }
        let cullDistance = size.width * 3
        
        let rightCull = cam.position.x + cullDistance
        let leftCull = cam.position.x - cullDistance
        
        groundSegments.removeAll { segment in
            let x = segment.position.x
            if x > rightCull || x < leftCull {
                segment.removeFromParent()
                return true
            }
            return false
        }
        
        if let rightmost = groundSegments.max(by: { $0.position.x < $1.position.x }) {
            lastGeneratedGroundX = rightmost.position.x
        }
        if let leftmost = groundSegments.min(by: { $0.position.x < $1.position.x }) {
            firstGeneratedGroundX = leftmost.position.x
        }
        
        platforms.removeAll { platform in
            let x = platform.position.x
            if x > rightCull || x < leftCull {
                platform.removeFromParent()
                return true
            }
            return false
        }
        
        if let rightmost = platforms.max(by: { $0.position.x < $1.position.x }) {
            lastGeneratedPlatformX = rightmost.position.x
        }
        if let leftmost = platforms.min(by: { $0.position.x < $1.position.x }) {
            firstGeneratedPlatformX = leftmost.position.x
        }
    }
}

extension TestGameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        
        let playerMask = PhysicsCategory.playerMe.rawValue
        let groundMask = PhysicsCategory.groundMe.rawValue
        
        let isPlayerA = (maskA & playerMask) != 0
        let isPlayerB = (maskB & playerMask) != 0
        let isGroundA = (maskA & groundMask) != 0
        let isGroundB = (maskB & groundMask) != 0
        
        if (isPlayerA && isGroundB) || (isPlayerB && isGroundA) {
            let playerBody = isPlayerA ? contact.bodyA : contact.bodyB
            let isFalling = playerBody.velocity.dy <= 0
            
            if isFalling {
                isGrounded = true
                jumpCount = 0
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        
        let playerMask = PhysicsCategory.playerMe.rawValue
        let groundMask = PhysicsCategory.groundMe.rawValue
        
        let isPlayerA = (maskA & playerMask) != 0
        let isPlayerB = (maskB & playerMask) != 0
        let isGroundA = (maskA & groundMask) != 0
        let isGroundB = (maskB & groundMask) != 0
        
        if (isPlayerA && isGroundB) || (isPlayerB && isGroundA) {
            isGrounded = false
        }
    }
}
