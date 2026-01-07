//
//  GameView.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

import Games
import InputSystem
import SpriteKit
import SwiftUI

public struct GameView: View {
    @State private var gameplayManager = GameplayManager()
    @State private var gameScene: GameScene?
    private let inputSystem = InputSystem(source: .faceTracking())

    public init() {}

    public var body: some View {
        ZStack {
            if let scene = gameScene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(Color.clear)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .task { // InputSystem -> GameplayManager 연결
            inputSystem.start()

            // AsyncStream 구독
            for await event in await inputSystem.events() {
                switch event {
                case .horizontal(let x):
                    gameplayManager.updateInput(moveX: x)

                case .action(let action, let value):
                    if action == .primary && value > 0.5 {
                        gameplayManager.tryJump()
                    }
                }
            }
        }
        .onDisappear {
            inputSystem.stop()
        }
        .onAppear {
            setupGame()
        }
    }

    private func setupGame() {
        let scene = GameScene(
            size: UIScreen.main.bounds.size,
            gameplayManager: gameplayManager
        )
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        gameScene = scene
    }
}
