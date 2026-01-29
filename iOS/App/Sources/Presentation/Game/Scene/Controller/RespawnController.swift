//
//  RespawnController.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/27/26.
//

import SpriteKit

final class RespawnController {
    private var buttonNode: SKSpriteNode?
    private weak var buttonParent: SKNode?

    private enum Layout {
        static let iconSize: CGFloat = 45
        static let topMargin: CGFloat = 60
        static let rightMargin: CGFloat = 30
    }

    // MARK: - Public

    func setup(in scene: SKScene, cameraNode: SKCameraNode?) {
        let texture = SKTexture(imageNamed: AppAsset.Image.respawnButtonIcon.name)
        let button = SKSpriteNode(texture: texture)
        button.name = L10N.Game.NodeName.respawnButton
        button.size = CGSize(width: Layout.iconSize, height: Layout.iconSize)
        button.zPosition = 10_000
        button.isHidden = false

        let parent = cameraNode ?? scene
        parent.addChild(button)
        buttonParent = parent
        buttonNode = button
        updateButtonPosition(sceneSize: scene.size)
    }

    func update(sceneSize: CGSize) {
        updateButtonPosition(sceneSize: sceneSize)
    }

    func handleTouch(_ touch: UITouch, in scene: SKScene) -> Bool {
        guard let button = buttonNode, button.isHidden == false else { return false }
        let parent = buttonParent ?? scene
        let location = touch.location(in: parent)
        let nodesAtPoint = parent.nodes(at: location)
        return nodesAtPoint.contains(where: { $0.name == L10N.Game.NodeName.respawnButton })
    }

    func resetAfterAction(sceneSize: CGSize) {
        updateButtonPosition(sceneSize: sceneSize)
    }

    // MARK: - Button

    private func updateButtonPosition(sceneSize: CGSize) {
        guard let button = buttonNode else { return }
        let insets = buttonParent?.scene?.view?.safeAreaInsets ?? .zero
        let rightInset = insets.right
        let topInset = insets.top
        button.position = CGPoint(
            x: (sceneSize.width / 2) - Layout.rightMargin - rightInset - (Layout.iconSize / 2),
            y: (sceneSize.height / 2) - Layout.topMargin - topInset - (Layout.iconSize / 2)
        )
    }

}
