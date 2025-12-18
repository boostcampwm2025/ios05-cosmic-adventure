import Combine
import SpriteKit

// MARK: - MapType

enum MapType {
    case flat   // 평면 맵 (가로로 넓은 테스트용)
    case tower  // 탑 맵 (지그재그 계단)
}

// MARK: - GameScene

final class GameScene: SKScene {
    private let gameplayManager: GameplayManager
    private var physicsController: PhysicsController?
    private var cameraSystem: CameraSystem?

    private var cancellables = Set<AnyCancellable>()

    private var playerNode: SKSpriteNode?
    
    // MARK: - 맵 설정
    
    private let mapType: MapType
    
    // 탑 맵 상수
    private let towerHalfWidth: CGFloat = 200
    private let towerHeight: CGFloat = 5000
    private let wallThickness: CGFloat = 30
    
    // 평면 맵 상수
    private let flatMapWidth: CGFloat = 3000
    private let flatMapHeight: CGFloat = 2000

    // MARK: - Init

    init(size: CGSize, gameplayManager: GameplayManager, mapType: MapType = .tower) {
        self.gameplayManager = gameplayManager
        self.mapType = mapType
        super.init(size: size)

        physicsWorld.gravity = CGVector(dx: 0, dy: PhysicsConstants.gravityDY)
        physicsWorld.contactDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to _: SKView) {
        setupMap()
        setupPlayer()
        setupSystems()
        bindGameplay()
    }

    override func update(_: TimeInterval) {
        let state = gameplayManager.state

        // 1. grounded 상태 동기화
        physicsController?.isGrounded = state.isGrounded

        // 2. 물리 반영 (이동)
        if state.isAlive {
            physicsController?.applyMovement(moveX: state.moveX)
        }
        
        // 3. Apex gravity 처리
        physicsController?.updateGravity()

        // 4. 카메라 추적
        cameraSystem?.update()

        // 5. 낙하(Out of bounds) 체크
        if let player = playerNode, player.position.y < -500 {
            gameplayManager.handleContact(.hazard)
        }

        // 6. One-way platform 충돌 제어
        updatePlatformCollisions()
    }

    // MARK: - Map Setup

    private func setupMap() {
        backgroundColor = .white
        
        switch mapType {
        case .flat:
            setupFlatMap()
        case .tower:
            setupTowerMap()
        }
    }
    
    // MARK: - Flat Map (평면 테스트용)
    
    private func setupFlatMap() {
        setupFlatMarkers()
        
        // 넓은 바닥
        let ground = SKSpriteNode(color: .gray, size: CGSize(width: flatMapWidth, height: 50))
        ground.position = CGPoint(x: 0, y: -200)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = CollisionCategory.ground
        ground.physicsBody?.contactTestBitMask = CollisionCategory.player
        ground.physicsBody?.collisionBitMask = CollisionCategory.all
        ground.physicsBody?.restitution = PhysicsConstants.restitution
        addChild(ground)
        
        // 테스트용 플랫폼 몇 개
        let platformPositions: [(x: CGFloat, y: CGFloat)] = [
            (-300, -50),
            (0, 50),
            (300, 150),
            (600, 100),
            (-200, 200),
            (200, 300),
        ]
        
        for pos in platformPositions {
            let platform = PlatformNode(size: CGSize(width: 150, height: 25))
            platform.position = CGPoint(x: pos.x, y: pos.y)
            addChild(platform)
        }
    }
    
    private func setupFlatMarkers() {
        let spacing: CGFloat = 100
        let halfWidth = flatMapWidth / 2
        let halfHeight = flatMapHeight / 2
        
        // 가로선
        let hLineCount = Int(flatMapHeight / spacing)
        for i in 0 ... hLineCount {
            let y = -halfHeight + spacing * CGFloat(i)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -halfWidth, y: y))
            path.addLine(to: CGPoint(x: halfWidth, y: y))

            let line = SKShapeNode(path: path)
            line.strokeColor = .black.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.zPosition = -10
            addChild(line)
        }

        // 세로선
        let vLineCount = Int(flatMapWidth / spacing)
        for i in 0 ... vLineCount {
            let x = -halfWidth + spacing * CGFloat(i)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: -halfHeight))
            path.addLine(to: CGPoint(x: x, y: halfHeight))

            let line = SKShapeNode(path: path)
            line.strokeColor = .black.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.zPosition = -10
            addChild(line)
        }
    }
    
    // MARK: - Tower Map (탑 맵)
    
    private func setupTowerMap() {
        setupTowerMarkers()
        setupWalls()
        
        // 탑 바닥
        let groundWidth = towerHalfWidth * 2
        let ground = SKSpriteNode(color: .gray, size: CGSize(width: groundWidth, height: 50))
        ground.position = CGPoint(x: 0, y: -200)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = CollisionCategory.ground
        ground.physicsBody?.contactTestBitMask = CollisionCategory.player
        ground.physicsBody?.collisionBitMask = CollisionCategory.all
        ground.physicsBody?.restitution = PhysicsConstants.restitution
        addChild(ground)

        setupStairs()
    }

    private func setupWalls() {
        let wallHeight = towerHeight
        let wallSize = CGSize(width: wallThickness, height: wallHeight)
        let wallCenterY = -200 + wallHeight / 2

        // 왼쪽 벽
        let leftWall = SKSpriteNode(color: .darkGray, size: wallSize)
        leftWall.position = CGPoint(x: -towerHalfWidth - wallThickness / 2, y: wallCenterY)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: wallSize)
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = CollisionCategory.wall
        leftWall.physicsBody?.collisionBitMask = CollisionCategory.player
        leftWall.physicsBody?.restitution = 0
        addChild(leftWall)

        // 오른쪽 벽
        let rightWall = SKSpriteNode(color: .darkGray, size: wallSize)
        rightWall.position = CGPoint(x: towerHalfWidth + wallThickness / 2, y: wallCenterY)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: wallSize)
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = CollisionCategory.wall
        rightWall.physicsBody?.collisionBitMask = CollisionCategory.player
        rightWall.physicsBody?.restitution = 0
        addChild(rightWall)
    }

    private func setupStairs() {
        let stepCount = 50
        let stepSize = CGSize(width: 100, height: 30)
        let stepHeightGap: CGFloat = 100

        let leftX: CGFloat = -80
        let rightX: CGFloat = 80
        let startY: CGFloat = -100

        for i in 0 ..< stepCount {
            let step = PlatformNode(size: stepSize)
            let xPosition = (i % 2 == 0) ? leftX : rightX
            let yPosition = startY + stepHeightGap * CGFloat(i)
            step.position = CGPoint(x: xPosition, y: yPosition)
            addChild(step)
        }
    }

    private func setupTowerMarkers() {
        let startY: CGFloat = -300
        let spacing: CGFloat = 100
        let lineCount = Int(towerHeight / spacing)

        // 가로선
        for i in 0 ... lineCount {
            let y = startY + spacing * CGFloat(i)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -towerHalfWidth, y: y))
            path.addLine(to: CGPoint(x: towerHalfWidth, y: y))

            let line = SKShapeNode(path: path)
            line.strokeColor = .black.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.zPosition = -10
            addChild(line)
        }

        // 세로선
        let verticalLineCount = Int(towerHalfWidth * 2 / spacing)
        for i in 0 ... verticalLineCount {
            let x = -towerHalfWidth + spacing * CGFloat(i)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: startY))
            path.addLine(to: CGPoint(x: x, y: startY + towerHeight))

            let line = SKShapeNode(path: path)
            line.strokeColor = .black.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.zPosition = -10
            addChild(line)
        }
    }
    
    // MARK: - Player Setup

    private func setupPlayer() {
        let player = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: 0, y: 0)

        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = CollisionCategory.player
        player.physicsBody?.contactTestBitMask = CollisionCategory.ground | CollisionCategory.platform | CollisionCategory.hazard
        player.physicsBody?.collisionBitMask = CollisionCategory.ground | CollisionCategory.wall | CollisionCategory.platform

        addChild(player)
        playerNode = player
    }

    // MARK: - Systems

    private func setupSystems() {
        guard let player = playerNode else { return }

        if let body = player.physicsBody {
            physicsController = PhysicsController(body: body)
        }

        cameraSystem = CameraSystem(scene: self)
        cameraSystem?.follow(player)
    }

    private func bindGameplay() {
        gameplayManager.jumpImpulseSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.physicsController?.jump()
            }
            .store(in: &cancellables)
    }

    // MARK: - One-way Platform

    private func updatePlatformCollisions() {
        guard let player = playerNode,
              let playerBody = player.physicsBody else { return }

        let playerBottom = player.position.y - player.size.height / 2
        let playerVelocityY = playerBody.velocity.dy

        enumerateChildNodes(withName: "//*") { node, _ in
            guard let platform = node as? PlatformNode,
                  let platformBody = platform.physicsBody else { return }

            let platformTop = platform.position.y + platform.size.height / 2
            let isAbovePlatform = playerBottom >= platformTop - 5
            let isFalling = playerVelocityY <= 0

            if isAbovePlatform && isFalling {
                platformBody.collisionBitMask = CollisionCategory.player
            } else {
                platformBody.collisionBitMask = CollisionCategory.none
            }
        }
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let otherMask = (maskA == CollisionCategory.player) ? maskB : maskA

        if otherMask == CollisionCategory.ground || otherMask == CollisionCategory.platform {
            gameplayManager.handleContact(.ground)
            physicsController?.isGrounded = true
        } else if otherMask == CollisionCategory.hazard {
            gameplayManager.handleContact(.hazard)
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let otherMask = (maskA == CollisionCategory.player) ? maskB : maskA

        if otherMask == CollisionCategory.ground || otherMask == CollisionCategory.platform {
            // 바닥에서 떨어짐
            physicsController?.isGrounded = false
        }
    }
}
