//
//  GameView.swift
//  App
//
//  Created by soyoung on 1/7/26.
//

import Games
import InputSystem
import VideoKit
import SpriteKit
import SwiftUI

struct GameView: View {
    @State private var viewModel: GameViewModel
    @State private var gameScene: GameScene?
    private var videoManager: VideoManager
    private let size = VideoConfiguration().displaySize

    private var gameplayManager: GameplayManager {
        viewModel.gameplayManager
    }
    
    private var inputProvider: FaceTrackingGameInputProvider {
        viewModel.inputProvider
    }
    
    init(viewModel: GameViewModel, videoManager: VideoManager) {
        _viewModel = State(initialValue: viewModel)
        self.videoManager = videoManager
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

            VStack(alignment: .leading, spacing: 12) {
                gameHUD

                // TODO: 2인 모드 (상대가 있을 때만)
//                if !otherPlayerIDs.isEmpty {
                    RemoteVideoView(layer: videoManager.remoteDisplayLayer)
                        .frame(width: size, height: size)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                        .zIndex(999)
//                }
            }
            .padding(16)

            if let reason = viewModel.endReason {
                gameEndOverlay(reason: reason)
            }
            
            facePreviewOverlay
        }
        .onAppear {
            setupGame()
            viewModel.start()
            UIApplication.shared.isIdleTimerDisabled = true

            inputProvider.onFrameUpdate = { pixelBuffer in
                // TODO: 2인모드 체크
                videoManager.processFrame(pixelBuffer: pixelBuffer)
            }
        }
        .onDisappear {
            viewModel.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: viewModel.endReason) { _, newValue in
            if newValue != nil {
                viewModel.stop()
            }
        }
    }
    
    private var facePreviewOverlay: some View {
        VStack(spacing: 16) {
            if let session = inputProvider.previewSession() {
                FacePreviewPIPView {
                    FacePreviewView(session: session)
                }
            }
        }
    }

    private func setupGame() {
        let otherExplorersByID: [UUID: LobbyExplorer] = {
            guard let peer = viewModel.matchPeer,
                  let remoteID = viewModel.otherPlayerIDs.first else {
                return [:]
            }
            return [remoteID: peer]
        }()
        
        let scene = GameScene(
            size: UIScreen.main.bounds.size,
            gameplayManager: gameplayManager,
            localExplorer: viewModel.me,
            otherExplorersByID: otherExplorersByID
        )
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        gameScene = scene
    }
    
    private var gameHUD: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let remain = viewModel.remainingSeconds {
                Text("남은 시간: \(remain)s")
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                    .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            } else {
                Text("경과 시간: \(viewModel.elapsedSeconds)s")
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

                Text("경과 시간: \(viewModel.elapsedSeconds)s")
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.opacity)
    }
}
