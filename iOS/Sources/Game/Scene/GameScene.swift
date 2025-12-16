import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var character: CharacterNode!
    var platforms: [PlatformNode] = []
    var cameraNode: SKCameraNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        
        setupPhysics()
        setupCamera()
        setupCharacter()
        setupPlatforms()
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = GameConfig.Physics.gravity
        physicsWorld.contactDelegate = self
        
        // 바닥 경계 생성 (테스트용)
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: -300)
        let groundBody = SKPhysicsBody(rectangleOf: CGSize(width: 1000, height: 20))
        groundBody.isDynamic = false
        groundBody.categoryBitMask = PhysicsCategory.boundary
        ground.physicsBody = groundBody
        addChild(ground)
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupCharacter() {
        character = CharacterNode()
        character.position = CGPoint(x: 0, y: -200)
        addChild(character)
    }
    
    private func setupPlatforms() {
        // 지그재그 패턴으로 플랫폼 생성
        for i in 0..<10 {
            let xOffset = (i % 2 == 0) ? -GameConfig.Platform.horizontalSpacing : GameConfig.Platform.horizontalSpacing
            let yOffset = CGFloat(i) * GameConfig.Platform.verticalSpacing
            let position = CGPoint(x: xOffset, y: -100 + yOffset)
            
            let platform = PlatformNode(position: position)
            platforms.append(platform)
            addChild(platform)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // 카메라가 캐릭터를 따라가도록 업데이트
        if let camera = camera, let character = character {
            // 부드러운 추적을 위해 lerp 사용 가능하지만 일단 단순 추적
            // 캐릭터보다 약간 위를 비추도록 설정
            let targetY = character.position.y + 100
            if targetY > camera.position.y {
                camera.position.y = targetY
            }
            
            // 캐릭터가 화면 아래로 떨어지면 리셋 (테스트용)
            // 화면 높이의 절반만큼 아래로 떨어지면 리셋
            if character.position.y < camera.position.y - size.height {
                resetGame()
            }
        }
    }
    
    private func resetGame() {
        character.position = CGPoint(x: 0, y: -200)
        character.physicsBody?.velocity = .zero
        character.resetJumpCount()
        camera?.position = .zero
    }
    
    // 외부에서 호출할 입력 메서드
    func handleJump(intensity: CGFloat) {
        character.jump(intensity: intensity)
    }
    
    func handleMove(intensity: CGFloat) {
        character.move(intensity: intensity)
    }

    // MARK: - SKPhysicsContactDelegate

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask

        let isCharacterInvolved = (a == PhysicsCategory.character) || (b == PhysicsCategory.character)
        let isLandingSurface = (a == PhysicsCategory.platform) || (b == PhysicsCategory.platform) || (a == PhysicsCategory.boundary) || (b == PhysicsCategory.boundary)

        guard isCharacterInvolved, isLandingSurface else { return }

        // 착지했을 때만 점프 카운트 리셋(상승 중 옆면 접촉 등은 제외)
        guard (character.physicsBody?.velocity.dy ?? 0) <= 0 else { return }
        character.resetJumpCount()
    }
}
