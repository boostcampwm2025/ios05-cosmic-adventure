//
//  OperationGuideView.swift
//  App
//
//  Created by 강윤서 on 1/15/26.
//

import SwiftUI

struct OperationGuideView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    @State private var isChecked: Bool = UserDefaultsList.Game.isGuideChecked

    let me: LobbyExplorer
    let peer: LobbyExplorer?

    var body: some View {
        BackgroundContainerView {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                GuideTitleView(title: L10N.Game.Guide.moveManual)
                    .padding(.top, 24)
                    .padding(.leading, 52)
                
                GuideImageView(image: AppAsset.Image.horizontalGuide.swiftUIImage)
                    .padding(.top, 48)
                    .padding(.horizontal, 58)
                
                // TODO: - Image GIF로 변환 필요
                guideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: L10N.Game.Guide.horizontalMove
                )
                .padding(.top, 21)
                
                GuideImageView(image: AppAsset.Image.jumpGuide.swiftUIImage)
                    .padding(.top, 21)
                    .padding(.horizontal, 58)
                
                // TODO: - Image GIF로 변환 필요
                guideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: L10N.Game.Guide.jumpManual,
                    subText: L10N.Game.Guide.doubleJumpManual
                )
                .padding(.top, 22)
                
                Spacer()
                
                PrimaryGradientButton(
                    title: isChecked ? L10N.Game.Guide.gameReady : L10N.Game.Guide.gotoVictoryCondition,
                    verticalPadding: 16
                ) {
                    if isChecked {
                        if let peer = peer {
                            router.push(.gameReady(me: me, peer: peer))
                        } else { // 1인 모드
                            router.push(.game)
                        }
                    } else {
                        router.push(.victoryGuide(me: me, peer: peer))
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
                
                Spacer()
            }
            .padding(.bottom, 59)
        }
    }
}

// MARK: - Components

private extension OperationGuideView {
    func guideManualRow(
        characterImage: Image,
        manualText: LocalizedStringKey,
        subText: LocalizedStringKey? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 27) {
            characterImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 67)
                .padding(.leading, 67)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(manualText)
                    .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                    .foregroundColor(.white)
                    .padding(.top, subText == nil ? 9 : 8)
                
                if let subText = subText {
                    Text(subText)
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 13))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    OperationGuideView(me: LobbyExplorer(role: .me, displayName: "나", avatar: .character1),
                       peer: LobbyExplorer(role: .peer, displayName: "상대", avatar: .character2))
        .environment(AppRouter())
}
