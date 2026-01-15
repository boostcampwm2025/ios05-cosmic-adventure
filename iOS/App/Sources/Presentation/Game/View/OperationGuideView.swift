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
    
    var body: some View {
        ZStack {
            BackgroundContainerView {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                GuideTitleView(title: Constants.Game.Guide.moveManual)
                
                GuideImageView(image: AppAsset.Image.horizontalGuide.swiftUIImage)
                    .padding(.top, 48)
                    .padding(.horizontal, 58)

                // TODO: - Image GIF로 변환 필요
                guideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: Constants.Game.Guide.horizontalMove
                )
                .padding(.top, 21)

                // TODO: - Image GIF로 변환 필요
                GuideImageView(image: AppAsset.Image.jumpGuide.swiftUIImage)
                    .padding(.top, 21)
                    .padding(.horizontal, 58)

                guideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: Constants.Game.Guide.jumpManual,
                    subText: Constants.Game.Guide.doubleJumpManual
                )
                .padding(.top, 22)

                Spacer()

                PrimaryGradientButton(
                    title: isChecked ? Constants.Game.Guide.gameReady : Constants.Game.Guide.gotoVictoryCondition,
                    verticalPadding: 16
                ) {
                    if isChecked {
                        router.push(.game)
                    } else {
                        router.push(.victoryGuide)
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
                    title: Constants.Game.Guide.neverShowAgain
                )
                .frame(maxWidth: .infinity)
                .padding(.bottom, 59)
            }
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
    OperationGuideView()
        .environment(AppRouter())
}
