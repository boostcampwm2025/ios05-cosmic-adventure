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
            
            backButton
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
        .navigationBarBackButtonHidden()
    }
    
    private var backButton: some View {
        VStack {
            HStack {
                Button {
                    router.pop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.leading, 32)
            .padding(.top, 16)
            Spacer()
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
