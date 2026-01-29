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
    
    var body: some View {
        BackgroundContainerView {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                GuideTitleView(title: L10N.Game.Guide.moveManual)
                    .padding(.top, 24)
                    .padding(.leading, 20)
                
                GuideImageView(image: AppAsset.Image.horizontalGuide.swiftUIImage)
                    .padding(.top, 48)
                    .padding(.horizontal, 58)
                
                // TODO: - Image GIF로 변환 필요
                GuideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: L10N.Game.Guide.horizontalMove
                )
                .padding(.top, 21)
                
                GuideImageView(image: AppAsset.Image.jumpGuide.swiftUIImage)
                    .padding(.top, 21)
                    .padding(.horizontal, 58)
                
                // TODO: - Image GIF로 변환 필요
                GuideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: L10N.Game.Guide.jumpManual,
                    subText: L10N.Game.Guide.doubleJumpManual
                )
                .padding(.top, 22)
                
                Spacer()
                
                PrimaryGradientButton(
                    title: L10N.Game.Guide.gotoVictoryCondition,
                    verticalPadding: 16
                ) {
                    router.push(.victoryGuide(localPlayer: localPlayer, remotePlayer: remotePlayer, isNetwork: isNetwork))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 59)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OperationGuideView(localPlayer: PlayerInfo(role: .local, displayName: "나", avatar: .character1),
                       remotePlayer: PlayerInfo(role: .remote, displayName: "상대", avatar: .character2),
                       isNetwork: false)
        .environment(AppRouter())
}
