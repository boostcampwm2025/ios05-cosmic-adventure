//
//  VictoryGuideView.swift
//  App
//
//  Created by 강윤서 on 1/15/26.
//

import SwiftUI

struct VictoryGuideView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    @State private var isChecked: Bool = UserDefaultsList.Game.isGuideChecked

    let me: LobbyExplorer
    let peer: LobbyExplorer?

    var body: some View {
        BackgroundContainerView {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                GuideTitleView(title: L10N.Game.Guide.victoryManual)
                    .padding(.top, 24)
                    .padding(.leading, 52)
                
                GuideImageView(image: AppAsset.Image.victoryConditionTime.swiftUIImage)
                    .padding(.top, 48)
                    .padding(.horizontal, 58)
                
                Text(L10N.Game.Guide.timeCondition)
                    .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 21)
                
                GuideImageView(image: AppAsset.Image.victoryConditionMonster.swiftUIImage)
                    .padding(.top, 60)
                    .padding(.horizontal, 58)
                
                Text(L10N.Game.Guide.monsterCondition)
                    .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
                
                Spacer()
                
                PrimaryGradientButton(
                    title: L10N.Game.Guide.gameReady,
                    verticalPadding: 16
                ) {
                    router.push(.game)
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
    }
}

#Preview {
    VictoryGuideView(me: LobbyExplorer(role: .me, displayName: "나", avatar: .character1),
                     peer: LobbyExplorer(role: .peer, displayName: "상대", avatar: .character2))
        .environment(AppRouter())
}
