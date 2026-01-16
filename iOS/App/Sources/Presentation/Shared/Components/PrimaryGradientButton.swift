//
//  PrimaryGradientButton.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PrimaryGradientButton: View {
    let title: LocalizedStringKey
    let startColor: Color
    let endColor: Color
    var cornerRadius: CGFloat = 18
    var verticalPadding: CGFloat = 20
    let action: () -> Void

    init(
        title: LocalizedStringKey,
        isSubtle: Bool = false,
        cornerRadius: CGFloat = 18,
        verticalPadding: CGFloat = 20,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.startColor = isSubtle
        ? AppAsset.Color.subButtonGradientStart.swiftUIColor
        : AppAsset.Color.buttonGradientStart.swiftUIColor
        self.endColor = isSubtle
        ? AppAsset.Color.subButtonGradientEnd.swiftUIColor
        : AppAsset.Color.buttonGradientEnd.swiftUIColor
        self.cornerRadius = cornerRadius
        self.verticalPadding = verticalPadding
        self.action = action
    }

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
