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
    // TODO: 네트워크계층이랑 연결할 수 있게 주입식으로 변경

    @State private var gameplayManager = GameplayManager()
    @State private var gameScene: GameScene?

    public init() {}

    public var body: some View {
        ZStack {
            AppAsset.Image.background.swiftUIImage
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            if let scene = gameScene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Spacer()
                AppAsset.Image.monsterOverlay.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .offset(y: 50)
            }
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(false)
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
