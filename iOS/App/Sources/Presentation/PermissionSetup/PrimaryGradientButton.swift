//
//  PrimaryGradientButton.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PrimaryGradientButton: View {
    let title: LocalizedStringKey
    let startColor: Color = Color("buttonGradientStart")
    let endColor: Color = Color("buttonGradientEnd")
    var cornerRadius: CGFloat = 18
    var verticalPadding: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
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
