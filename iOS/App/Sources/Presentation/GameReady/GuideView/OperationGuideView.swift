//
//  OperationGuideView.swift
//  App
//
//  Created by 강윤서 on 1/15/26.
//

import SwiftUI

struct OperationGuideView: View {
    @Environment(AppRouter.self) private var router: AppRouter

    let localPlayer: PlayerInfo
    let remotePlayer: PlayerInfo?
    let isNetwork: Bool
    private let screenHeight = Metrics.screenHeight

    var body: some View {
        ZStack {
            BackgroundContainerView {
                Color.black.opacity(0.4)
            }

            VStack(alignment: .leading, spacing: 0) {
                GuideTitleView(title: L10N.Game.Guide.moveManual)
                    .padding(.top, 24)
                    .padding(.leading, 20)

                Spacer()

                GuideImageView(image: AppAsset.Image.horizontalGuide.swiftUIImage,
                               imageSize: GuideLayoutConfiguration.imageSize(for: screenHeight))
                .padding(.horizontal, GuideLayoutConfiguration.horizontalPadding(for: screenHeight))

                Spacer()

                GuideManualRow(
                    characterImage: AppAsset.Image.character1Walk.swiftUIImage,
                    characterImageSize: GuideLayoutConfiguration.iconSize(for: screenHeight),
                    manualText: L10N.Game.Guide.horizontalMove
                )

                Spacer()

                GuideImageView(image: AppAsset.Image.jumpGuide.swiftUIImage,
                               imageSize: GuideLayoutConfiguration.imageSize(for: screenHeight))
                .padding(.horizontal, GuideLayoutConfiguration.horizontalPadding(for: screenHeight))


                Spacer()

                GuideManualRow(
                    characterImage: AppAsset.Image.character1Jump.swiftUIImage,
                    characterImageSize: GuideLayoutConfiguration.iconSize(for: screenHeight),
                    manualText: L10N.Game.Guide.jumpManual,
                    subText: L10N.Game.Guide.doubleJumpManual
                )

                Spacer()

                PrimaryGradientButton(
                    title: L10N.Game.Guide.gotoVictoryCondition,
                    verticalPadding: 16
                ) {
                    router.push(.victoryGuide(localPlayer: localPlayer, remotePlayer: remotePlayer, isNetwork: isNetwork))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                Rectangle()
                    .frame(height: 20)
                    .foregroundStyle(.clear)
                    .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OperationGuideView(localPlayer: PlayerInfo(role: .local, displayName: "나", avatar: .character1),
                       remotePlayer: PlayerInfo(role: .remote, displayName: "상대", avatar: .character2),
                       isNetwork: false)
        .environment(AppRouter())
}
