//
//  TestGamePreviewView.swift
//  App
//

import ARKit
import SpriteKit
import SwiftUI

struct TestGamePreviewView: View {
    @Environment(AppRouter.self) private var router
    
    @State private var scene: TestGameScene?
    private let inputProvider: FaceTrackingGameInputProvider
    private let gameConfig: GameConfigProviding
    
    init(gameConfig: GameConfigProviding) {
        self.gameConfig = gameConfig
        self.inputProvider = FaceTrackingGameInputProvider(
            jumpSensitivity: gameConfig.jumpSensitivity,
            tiltSensitivity: gameConfig.tiltSensitivity
        )
    }
    
    var body: some View {
        ZStack {
            AppAsset.Image.background.swiftUIImage
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }
            
            facePreviewOverlay
        }
        .onAppear {
            setupScene()
            inputProvider.start()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            inputProvider.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                }
            }
        }
    }
    
    private var facePreviewOverlay: some View {
        VStack {
            if let session = inputProvider.previewSession() {
                let sizeStyle = FacePreviewPIPView<FacePreviewView>.SizeStyle(
                    from: gameConfig.facePreviewSize
                )
                FacePreviewPIPView(sizeStyle: sizeStyle) {
                    FacePreviewView(session: session)
                }
            }
        }
    }
    
    private func setupScene() {
        let newScene = TestGameScene(
            size: UIScreen.main.bounds.size,
            inputProvider: inputProvider
        )
        newScene.scaleMode = .aspectFill
        newScene.backgroundColor = .clear
        scene = newScene
    }
}
