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
    
    var body: some View {
        BackgroundContainerView {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                GuideTitleView(title: L10N.Game.Guide.victoryManual)
                    .padding(.top, 24)
                    .padding(.leading, 20)
                
                GuideImageView(image: AppAsset.Image.victoryConditionTime.swiftUIImage)
                    .padding(.top, 48)
                    .padding(.horizontal, 58)
                
                GuideManualRow(manualText: L10N.Game.Guide.timeCondition)
                    .padding(.top, 21)
                
                GuideImageView(image: AppAsset.Image.victoryConditionMonster.swiftUIImage)
                    .padding(.top, 60)
                    .padding(.horizontal, 58)
                
                GuideManualRow(manualText: L10N.Game.Guide.monsterCondition)
                    .padding(.top, 22)
                
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
                .padding(.top, 44)
                
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
                
                Spacer()
            }
            .padding(.bottom, 59)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    VictoryGuideView(localPlayer: PlayerInfo(role: .local, displayName: "나", avatar: .character1),
                     remotePlayer: PlayerInfo(role: .remote, displayName: "상대", avatar: .character2),
                     isNetwork: false)
        .environment(AppRouter())
}
