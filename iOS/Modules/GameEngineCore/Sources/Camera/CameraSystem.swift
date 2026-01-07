//
//  CameraSystem.swift
//  GameEngineCore
//
//  Created by soyoung on 1/7/26.
//

import SpriteKit

public final class CameraSystem {
    public let cameraNode: SKCameraNode
    private weak var targetNode: SKNode? // 플레이어
    private let smoothing: CGFloat // 따라가는 속도 (0.0 ~ 1.0)

    public init(scene: SKScene, smoothing: CGFloat = 0.1) {
        self.smoothing = smoothing
        self.cameraNode = SKCameraNode()

        scene.addChild(cameraNode)
        scene.camera = cameraNode

        // 초기 위치
        cameraNode.position = CGPoint(x: 0, y: 0)
    }

    public func follow(_ node: SKNode) {
        targetNode = node
    }

    // 위치 설정 (리스폰 시)
    public func setPosition(_ position: CGPoint) {
        cameraNode.position = position
    }

    // 매 프레임 업데이트
    public func update() {
        guard let target = targetNode else { return }

        // 플레이어가 카메라보다 높이 올라갔을 때만 따라감
        if target.position.y > cameraNode.position.y {
            let currentY = cameraNode.position.y
            let targetY = target.position.y

            // 부드럽게 따라가기 (lerp)
            let newY = CGFloat.lerp(start: currentY, end: targetY, t: smoothing)

            // X축은 0으로 고정, Y축만 갱신
            cameraNode.position = CGPoint(x: 0, y: newY)
        }
    }
}
