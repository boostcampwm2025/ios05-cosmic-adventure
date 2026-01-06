//
//  PrimaryGradientButton.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PrimaryGradientButton: View {
    let title: LocalizedStringKey
    let startColor: Color = AppAsset.Color.buttonGradientStart.swiftUIColor
    let endColor: Color = AppAsset.Color.buttonGradientEnd.swiftUIColor
    var cornerRadius: CGFloat = 18
    var verticalPadding: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .background(
                    LinearGradient(
                        colors: [startColor, endColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        }
    }
}
