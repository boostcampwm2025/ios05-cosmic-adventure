//
//  PermissionCard.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PermissionCard: View {
    let iconImage: Image
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 14) {
            iconImage
                .resizable()
                .scaledToFit()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                    .foregroundStyle(AppAsset.Color.blackLabel.swiftUIColor)

                Text(subtitle)
                    .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 13))
                    .foregroundStyle(AppAsset.Color.subBlackLabel.swiftUIColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            AppAsset.Color.permissionCardBackground.swiftUIColor
                .opacity(0.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(
                cornerRadius: 16, style: .continuous
            )
            .stroke(.white, lineWidth: 1)
        )
    }
}
