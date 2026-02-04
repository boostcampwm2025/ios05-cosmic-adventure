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
    @Environment(AppRouter.self) private var router: AppRouter
    @State private var viewModel: GameViewModel
    @State private var gameScene: GameScene?
    @State private var isMenuPresented: Bool = false
    private var videoManager: VideoManager
    private let size = VideoConfiguration().displaySize

    private var gameplayManager: GameplayManager {
        viewModel.gameplayManager
    }
    
    private var inputProvider: FaceTrackingGameInputProvider {
        viewModel.inputProvider
    }
    
    private var gameConfig: GameConfigProviding {
        viewModel.gameConfig
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
                    .allowsHitTesting(true)
            }

            if !viewModel.remotePlayerIDs.isEmpty {
                RemoteVideoView(layer: videoManager.remoteDisplayLayer)
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .position(
                        x: clampX(viewModel.remotePlayerScreenPosition.x),
                        y: clampY(viewModel.remotePlayerScreenPosition.y - size)
                    )
                    .zIndex(1)
            }

            if isMenuPresented {
                menuOverlay
                    .zIndex(10)
            }

            facePreviewOverlay
                .zIndex(1)

            if let reason = viewModel.endReason {
                gameEndOverlay(reason: reason)
                    .zIndex(10)
            }
            
            if viewModel.showDisconnectAlert {
                disconnectAlertOverlay
                    .zIndex(10)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                gameHUD
                Spacer()
                HStack(spacing: 12) {
                    respawnButton
                    menuButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onAppear {
            setupGame()
            viewModel.start()
            UIApplication.shared.isIdleTimerDisabled = true

            videoManager.setTargetPlayer(viewModel.remotePlayer)
            videoManager.startLatencyMonitoring()
            inputProvider.onFrameUpdate = { pixelBuffer in
                videoManager.processFrame(pixelBuffer: pixelBuffer)
            }
        }
        .onDisappear {
            viewModel.stop()
            UIApplication.shared.isIdleTimerDisabled = false

            inputProvider.onFrameUpdate = nil
            videoManager.stopLatencyMonitoring()
        }
        .onChange(of: viewModel.endReason) { _, newValue in
            guard let reason = newValue else { return }
            viewModel.updateLocalGameEndDisplay(reason)
            viewModel.notifyGameEnded(reason)
            viewModel.stop()
        }
        .onChange(of: viewModel.shouldNavigateToResult) { _, shouldNavigate in
            if shouldNavigate, let display = viewModel.gameEndDisplay {
                router.push(.gameResult(
                    display: display,
                    localPlayer: viewModel.localPlayer,
                    remotePlayer: viewModel.remotePlayer
                ))
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var facePreviewOverlay: some View {
        VStack(spacing: 16) {
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

    private func setupGame() {
        let remotePlayersByID: [UUID: PlayerInfo] = {
            guard let peer = viewModel.remotePlayer,
                  let remoteID = viewModel.remotePlayerIDs.first else {
                return [:]
            }
            return [remoteID: peer]
        }()
        
        let scene = GameScene(
            size: UIScreen.main.bounds.size,
            gameplayManager: gameplayManager,
            localPlayer: viewModel.localPlayer,
            remotePlayersByID: remotePlayersByID
        )
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        gameScene = scene

        // 상대 플레이어 위치 콜백 바인딩
        viewModel.bindRemotePlayerPosition(scene: scene)
    }

    /// X 좌표를 화면 경계 내로 제한
    private func clampX(_ x: CGFloat) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let halfSize = size / 2
        return min(max(x, halfSize), screenWidth - halfSize)
    }

    /// Y 좌표를 화면 경계 내로 제한
    private func clampY(_ y: CGFloat) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let halfSize = size / 2
        return min(max(y, halfSize), screenHeight - halfSize)
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
        .allowsHitTesting(false)
    }

    private var menuButton: some View {
        Button {
            isMenuPresented = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [
                            AppAsset.Color.iconGradientStart.swiftUIColor,
                            AppAsset.Color.iconGradientEnd.swiftUIColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
        }
    }

    private var respawnButton: some View {
        Button {
            viewModel.requestRespawn()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [
                            AppAsset.Color.iconGradientStart.swiftUIColor,
                            AppAsset.Color.iconGradientEnd.swiftUIColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
        }
    }

    private var menuOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { isMenuPresented = false }

            VStack(spacing: 12) {
                Text(L10N.Game.Menu.title)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 18))
                    .foregroundStyle(.white)

                Button(L10N.Game.Menu.quit) {
                    isMenuPresented = false
                    viewModel.requestQuitGame()
                }
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 16))
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button(L10N.Game.Menu.close) {
                    isMenuPresented = false
                }
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 16))
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(20)
            .background(.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func gameEndOverlay(reason: GameEndReason) -> some View {
        let title = viewModel.gameEndReasonText ?? {
            switch reason {
            case .timeout: return L10N.Game.End.timeoutTitle
            case .reachedFinish: return L10N.Game.End.finishTitle
            case .quit: return L10N.Game.End.quitTitle
            }
        }()

        return ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(title)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 32))
                    .foregroundStyle(.white)

                if let winnerText = viewModel.gameEndWinnerText {
                    Text(winnerText)
                        .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 22))
                        .foregroundStyle(.white)
                }

                if let opponentText = viewModel.gameEndOpponentText {
                    Text(opponentText)
                        .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 18))
                        .foregroundStyle(.white.opacity(0.85))
                }

                if let opponentElapsed = viewModel.gameEndOpponentElapsedText {
                    Text(opponentElapsed)
                        .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 18))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Button(L10N.Game.End.backToLobby) {
                    router.resetToHome()
                }
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(AppAsset.Color.buttonGradientStart.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(20)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.opacity)
    }

    // MARK: - Disconnect Alert

    private var disconnectAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack {
                Spacer()
                disconnectAlertSheet
            }
            .transition(.move(edge: .bottom))
            .ignoresSafeArea(edges: .bottom)
            .zIndex(999)
        }
    }

    private var disconnectAlertSheet: some View {
        VStack(spacing: 24) {
            disconnectAlertHeader
            disconnectAlertContent
            disconnectAlertButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 40)
        .background(AppAsset.Color.sheetBackground.swiftUIColor)
        .clipShape(
            .rect(
                topLeadingRadius: 40,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 40
            )
        )
        .shadow(radius: 30)
    }

    private var disconnectAlertHeader: some View {
        HStack {
            Image(systemName: "wifi.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 22)
            Text(L10N.Game.Disconnect.title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
    }

    private var disconnectAlertContent: some View {
        Text(L10N.Game.Disconnect.subtitle)
            .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 18))
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
    }

    private var disconnectAlertButton: some View {
        PrimaryGradientButton(
            title: L10N.Game.Disconnect.returnButton,
            cornerRadius: 16,
            verticalPadding: 20
        ) {
            router.resetToHome()
        }
    }
}
