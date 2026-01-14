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
    
    public init(endCondition: any GameEndCondition = TimeoutOrFinishEndCondition(limit: 30, targetPlatformIndex: 4)) {
        _gameplayManager = State(initialValue: GameplayManager(endCondition: endCondition))
    }
    
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
            
            gameHUD

            if let reason = gameplayManager.endReason {
                gameEndOverlay(reason: reason)
            }
            
            facePreviewOverlay
        }
        .onAppear {
            setupGame()
            gameplayManager.startNewGame()
            gameplayManager.bind(input: inputProvider)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            gameplayManager.unbind()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: gameplayManager.endReason) { _, newValue in
            if newValue != nil {
                gameplayManager.unbind()
            }
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
        Group {
            if let session = inputProvider.previewSession() {
                FacePreviewPIPView {
                    FacePreviewView(session: session)
                }
            }
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
    
    private var gameHUD: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let remain = gameplayManager.remainingSeconds {
                Text("남은 시간: \(remain)s")
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                    .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            } else {
                Text("경과 시간: \(gameplayManager.elapsedSeconds)s")
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                    .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            }
        }
        .padding(12)
        .background(.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .allowsHitTesting(false)
    }

    private func gameEndOverlay(reason: GameEndReason) -> some View {
        let title: String
        switch reason {
        case .timeout:
            title = "시간 종료"
        case .reachedFinish:
            title = "결승 도착!"
        }

        return ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(title)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 32))
                    .foregroundStyle(.white)

                Text("경과 시간: \(gameplayManager.elapsedSeconds)s")
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.opacity)
    }
    
}
