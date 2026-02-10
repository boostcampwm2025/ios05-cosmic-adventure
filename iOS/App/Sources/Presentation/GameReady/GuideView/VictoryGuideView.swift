//
//  VictoryGuideView.swift
//  App
//
//  Created by 강윤서 on 1/15/26.
//

import SwiftUI

struct VictoryGuideView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    @Environment(AppEntryManager.self) private var appEntryManager: AppEntryManager
    @State private var isChecked: Bool = UserDefaultsList.Game.isGuideChecked
    
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
                GuideTitleView(title: L10N.Game.Guide.victoryManual)
                    .padding(.top, 24)
                    .padding(.leading, 20)
                
                Spacer()
                
                GuideImageView(image: AppAsset.Image.victoryConditionTime.swiftUIImage,
                               imageSize: GuideLayoutConfiguration.imageSize(for: screenHeight))
                .padding(.horizontal, GuideLayoutConfiguration.horizontalPadding(for: screenHeight))
                
                Spacer()
                
                GuideManualRow(characterImage: AppAsset.Image.character1Flag.swiftUIImage,
                               characterImageSize: GuideLayoutConfiguration.iconSize(for: screenHeight),
                               manualText: L10N.Game.Guide.timeCondition)
                
                Spacer()
                
                GuideImageView(image: AppAsset.Image.victoryConditionMonster.swiftUIImage,
                               imageSize: GuideLayoutConfiguration.imageSize(for: screenHeight))
                .padding(.horizontal, GuideLayoutConfiguration.horizontalPadding(for: screenHeight))
                
                Spacer()
                
                GuideManualRow(characterImage: AppAsset.Image.character1Surprise.swiftUIImage,
                               characterImageSize: GuideLayoutConfiguration.iconSize(for: screenHeight),
                               manualText: L10N.Game.Guide.monsterCondition)
                
                Spacer()
                
                PrimaryGradientButton(
                    title: L10N.Game.Guide.gameReady,
                    verticalPadding: 16
                ) {
                    Task { @MainActor in
                        guard await appEntryManager.canEnterGame() else { return }
                        router.push(.gameReady(localPlayer: localPlayer, remotePlayer: remotePlayer, isNetwork: isNetwork))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                CheckButton(
                    isChecked: Binding(
                        get: { isChecked },
                        set: { newValue in
                            isChecked = newValue
                            UserDefaultsList.Game.isGuideChecked = newValue
                        }
                    ),
                    title: L10N.Game.Guide.neverShowAgain
                )
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    VictoryGuideView(localPlayer: PlayerInfo(role: .local, displayName: "나", avatar: .character1),
                     remotePlayer: PlayerInfo(role: .remote, displayName: "상대", avatar: .character2),
                     isNetwork: false)
        .environment(AppRouter())
}
