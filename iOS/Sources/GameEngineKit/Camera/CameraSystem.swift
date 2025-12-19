import SpriteKit

/// 캐릭터를 추적하는 카메라 시스템
public final class CameraSystem {
    public let cameraNode: SKCameraNode
    private weak var targetNode: SKNode?

    private let smoothing: CGFloat = 0.1 // 0.0 ~ 1.0 (낮을수록 부드럽고 느림)
    private let yOffset: CGFloat = 100.0 // 캐릭터보다 살짝 위를 비춤

    public init(scene: SKScene) {
        cameraNode = SKCameraNode()
        scene.addChild(cameraNode)
        scene.camera = cameraNode
    }

    // MARK: - Setup

    public func follow(_ node: SKNode) {
        targetNode = node
    }

    // MARK: - Update

    public func update() {
        guard let target = targetNode else { return }

        // 현재 카메라 위치
        let currentPos = cameraNode.position

        // 목표 위치 (타겟 + 오프셋)
        // X축: 타겟 따라감
        // Y축: 타겟 따라가되 오프셋 적용 (플랫포머에서는 Y축 고정하거나 제한을 두기도 함)
        let targetPos = CGPoint(x: target.position.x, y: target.position.y + yOffset)

        let newX = lerp(currentPos.x, targetPos.x, smoothing)
        let newY = lerp(currentPos.y, targetPos.y, smoothing)

        cameraNode.position = CGPoint(x: newX, y: newY)
    }
}
