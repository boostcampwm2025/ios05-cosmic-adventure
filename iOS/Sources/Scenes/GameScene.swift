import Combine
import SpriteKit

final class GameScene: SKScene {
    private let gameplayManager: GameplayManager
    private var physicsController: PhysicsController?
    private var cameraSystem: CameraSystem?

    private var cancellables = Set<AnyCancellable>()

    private var playerNode: SKSpriteNode?

    init(size: CGSize, gameplayManager: GameplayManager) {
        self.gameplayManager = gameplayManager
        super.init(size: size)

        // Physics World 설정
        physicsWorld.gravity = CGVector(dx: 0, dy: PhysicsConstants.gravityDY)
        physicsWorld.contactDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to _: SKView) {
        setupNodes()
        setupSystems()
        bindGameplay()
    }

    private var lastLogTime: TimeInterval = 0

    override func update(_: TimeInterval) {
        // 1. Gameplay 상태 가져오기
        let state = gameplayManager.state

        // 2. 물리 반영 (이동)
        if state.isAlive {
            physicsController?.applyMovement(moveX: state.moveX)
        }

        // 3. 카메라 추적
        cameraSystem?.update()

        // 4. 낙하(Out of bounds) 체크 (간단한 Y축 체크)
        if let player = playerNode, player.position.y < -500 {
            gameplayManager.handleContact(.hazard)
        }
    }

    // MARK: - Setup

    private func setupNodes() {
        // 배경
        backgroundColor = .white

        setupMarkers()

        // 1. 바닥 (Ground)
        let ground = SKSpriteNode(color: .gray, size: CGSize(width: 2000, height: 50))
        ground.position = CGPoint(x: 0, y: -200)

        // 바닥 물리
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = CollisionCategory.ground
        ground.physicsBody?.contactTestBitMask = CollisionCategory.player // 플레이어와 닿으면 알림
        ground.physicsBody?.collisionBitMask = CollisionCategory.all
        ground.physicsBody?.restitution = PhysicsConstants.restitution

        addChild(ground)

        // 2. 플레이어 (Player)
        let player = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: 0, y: 0)

        // 플레이어 물리
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = CollisionCategory.player
        player.physicsBody?.contactTestBitMask = CollisionCategory.ground | CollisionCategory.hazard
        player.physicsBody?.collisionBitMask = CollisionCategory.ground | CollisionCategory.wall

        addChild(player)
        playerNode = player
    }

    /// 테스트/튜닝용 마커 설정
    private func setupMarkers() {
        let startY: CGFloat = -1000
        let spacing: CGFloat = 100
        let lineCount = 200
        let halfWidth: CGFloat = 1500
        let width = halfWidth * 2

        // 1. 가로선 (ㅡ) : y축 이동(상승/하강) 체감용
        for i in 0 ... lineCount {
            let y = startY + spacing * CGFloat(i)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -halfWidth, y: y))
            path.addLine(to: CGPoint(x: halfWidth, y: y))

            let line = SKShapeNode(path: path)
            line.strokeColor = .black.withAlphaComponent(0.1)
            line.lineWidth = 1
            line.zPosition = -10
            addChild(line)
        }

        // 2. 세로선 (|) : x축 이동(좌우) 체감용
        let verticalLineCount = Int(width / spacing)
        for i in 0 ... verticalLineCount {
            let x = -halfWidth + spacing * CGFloat(i)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: startY))
            path.addLine(to: CGPoint(x: x, y: startY + spacing * CGFloat(lineCount)))

            let line = SKShapeNode(path: path)
            line.strokeColor = .black.withAlphaComponent(0.1)
            line.lineWidth = 1
            line.zPosition = -10
            addChild(line)
        }
    }

    private func setupSystems() {
        guard let player = playerNode else { return }

        if let body = player.physicsBody {
            physicsController = PhysicsController(body: body)
        }

        cameraSystem = CameraSystem(scene: self)
        cameraSystem?.follow(player)
    }

    private func bindGameplay() {
        // 점프 명령 구독
        gameplayManager.jumpImpulseSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.physicsController?.jump()
            }
            .store(in: &cancellables)
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // 충돌체 확인 (A, B 중 누가 플레이어인지 모름)
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

        // 충돌 대상 찾기 (플레이어가 아닌 쪽)
        let otherMask = (maskA == CollisionCategory.player) ? maskB : maskA

        // GameplayManager에 사실 전달
        if otherMask == CollisionCategory.ground {
            gameplayManager.handleContact(.ground)
        } else if otherMask == CollisionCategory.hazard {
            gameplayManager.handleContact(.hazard)
        }
    }
}
