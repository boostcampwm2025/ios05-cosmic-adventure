//
//  GameView.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

import Games
import SpriteKit
import SwiftUI

public struct GameView: View {
    @State private var gameplayManager = GameplayManager()
    @State private var gameScene: GameScene?

    public init() {}

    public var body: some View {
        ZStack {
            if let scene = gameScene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(Color.clear)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            setupGame()
            gameplayManager.bind(input: FaceTrackingGameInputProvider())
        }
        .onDisappear {
            gameplayManager.unbind()
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
