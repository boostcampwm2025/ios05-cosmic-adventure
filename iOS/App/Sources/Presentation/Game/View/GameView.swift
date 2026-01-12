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
    // TODO: 네트워크계층이랑 연결할 수 있게 주입식으로 변경

    @State private var gameplayManager = GameplayManager()
    @State private var gameScene: GameScene?
    @State private var inputProvider = FaceTrackingGameInputProvider()
    
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
                        
            facePreviewOverlay
                .padding( 20)
        }
        .onAppear {
            setupGame()
            gameplayManager.bind(input: inputProvider)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            gameplayManager.unbind()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private var monsterOverlay: some View {
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
    
    private var facePreviewOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                if let session = inputProvider.previewSession() {
                    FacePreviewView(session: session)
                        .frame(width: 140, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(radius: 6)
                }
            }
        }
        .allowsHitTesting(false)
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
