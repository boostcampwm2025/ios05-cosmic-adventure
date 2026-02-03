//
//  GameResultView.swift
//  App
//
//  Created by soyoung on 2/3/26.
//

import SwiftUI

struct GameResultView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    let display: GameViewModel.GameEndDisplay
    let localPlayer: PlayerInfo
    let remotePlayer: PlayerInfo?

    private var isWin: Bool {
        (display.winnerId == localPlayer.id) || (remotePlayer == nil && display.reason == .reachedFinish)
    }

    private var isDecisiveWin: Bool {
        (display.reason == .timeout) && isWin && (remotePlayer != nil)
    }

    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [AppAsset.Color.buttonGradientStart.swiftUIColor, AppAsset.Color.buttonGradientEnd.swiftUIColor],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var borderStyle: AnyShapeStyle {
        isWin ? AnyShapeStyle(brandGradient) : AnyShapeStyle(AppAsset.Color.subButton.swiftUIColor)
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 45) {
                Spacer()

                resultTitleView

                characterIllustrationView

                resultInfoCard

                Spacer()

                backToLobbyButton
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Subviews
private extension GameResultView {

    private var backgroundLayer: some View {
        AppAsset.Image.background.swiftUIImage
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
    }

    private var resultTitleView: some View {
        ZStack {
            let titleText = getResultTitle()
            let font = AppFontFamily.Pretendard.bold.swiftUIFont(size: 60)
            let strokeWidth: CGFloat = 3.5

            Group {
                Text(titleText).offset(x:  strokeWidth, y:  strokeWidth)
                Text(titleText).offset(x: -strokeWidth, y: -strokeWidth)
                Text(titleText).offset(x: -strokeWidth, y:  strokeWidth)
                Text(titleText).offset(x:  strokeWidth, y: -strokeWidth)
                Text(titleText).offset(x:  strokeWidth, y:  0)
                Text(titleText).offset(x: -strokeWidth, y:  0)
                Text(titleText).offset(x:  0, y:  strokeWidth)
                Text(titleText).offset(x:  0, y: -strokeWidth)
            }
            .font(font)
            .foregroundStyle(borderStyle)

            Text(titleText)
                .font(font)
                .foregroundStyle(.white)
        }
    }

    private var characterIllustrationView: some View {
        VStack(spacing: 20) {
            if isDecisiveWin {
                VStack(spacing: -15) {
                    avatarImage
                    AppAsset.Image.platform.swiftUIImage.resizable().scaledToFit().frame(width: 180)
                }
            } else if isWin {
                AppAsset.Image.goalRocket.swiftUIImage.resizable().scaledToFit().frame(width: 180)
            } else {
                AppAsset.Image.failMonster.swiftUIImage.resizable().scaledToFit().frame(width: 180)
            }

            if let remotePlayer = remotePlayer {
                Text("\(L10N.Game.End.opponentPrefix) : \(remotePlayer.displayName)")
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                    .foregroundStyle(.white)
            }
        }
    }

    private var avatarImage: some View {
        localPlayer.avatar.image
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .zIndex(1)
    }

    private var resultInfoCard: some View {
        VStack(spacing: 16) {
            resultRow(title: L10N.Game.End.elapsedTime, value: "\(display.localElapsedSeconds ?? 0) 초")
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 24).fill(AppAsset.Color.sheetBackground.swiftUIColor))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(borderStyle, lineWidth: 5))
        .padding(.horizontal, 40)
    }

    private var backToLobbyButton: some View {
        Button {
            router.resetToHome()
        } label: {
            Text(L10N.Game.End.backToLobby)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(isWin ? AnyShapeStyle(brandGradient) : AnyShapeStyle(AppAsset.Color.subButton.swiftUIColor))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    func resultRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(borderStyle)
                .opacity(0.8)
            Spacer()
            Text(value)
                .bold()
                .foregroundStyle(borderStyle)
        }
        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 19))
    }

    private func getResultTitle() -> String {
        if remotePlayer == nil {
            return isWin ? L10N.Game.End.successTitle : L10N.Game.End.failTitle
        } else {
            if isDecisiveWin { return L10N.Game.End.decisiveWinTitle }
            return isWin ? L10N.Game.End.winTitle : L10N.Game.End.loseTitle
        }
    }
}
