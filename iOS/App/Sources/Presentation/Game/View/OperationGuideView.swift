//
//  OperationGuideView.swift
//  App
//
//  Created by 강윤서 on 1/15/26.
//

import SwiftUI

struct OperationGuideView: View {
    @State private var isChecked: Bool = false
    
    var body: some View {
        ZStack {
            BackgroundContainerView {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                titleView
                
                guideImageView(image: AppAsset.Image.horizontalGuide.swiftUIImage)
                    .padding(.top, 48)
                    .padding(.horizontal, 58)

                guideManualRow(
                    characterImage: AppAsset.Image.character1.swiftUIImage,
                    manualText: Constants.Game.Guide.horizontalMove
                )
                .padding(.top, 21)
                
                guideImageView(image: AppAsset.Image.jumpGuide.swiftUIImage)
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
                    title: Constants.Game.Guide.gotoVictoryCondition,
                    verticalPadding: 16
                ) {
                    // TODO: 두번째 가이드 뷰로 이동 (구현 예정)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .padding(.top, 44)

                checkButtonView(
                    isChecked: $isChecked,
                    title: Constants.Game.Guide.neverShowAgain
                )
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Components

private extension OperationGuideView {
    var titleView: some View {
        Text(Constants.Game.Guide.moveManual)
            .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 32))
            .foregroundColor(.white)
            .padding(.top, 41)
            .padding(.leading, 39)
    }
    
    var victoryConditionButton: some View {
        Button(action: {
            // TODO: 두번째 가이드 뷰로 이동 (구현 예정)
        }) {
            Text(Constants.Game.Guide.gotoVictoryCondition)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            AppAsset.Color.buttonGradientStart.swiftUIColor,
                            AppAsset.Color.buttonGradientEnd.swiftUIColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
        }
    }
    
    func guideImageView(image: Image?) -> some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
            } else {
                Color.clear
                    .frame(height: 160)
            }
        }
    }
    
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
    
    func checkButtonView(isChecked: Binding<Bool>,
                         title: LocalizedStringKey) -> some View {
        HStack(spacing: 9) {
            Button(action: { isChecked.wrappedValue.toggle() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isChecked.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text(title)
                .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 15))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    OperationGuideView()
}
