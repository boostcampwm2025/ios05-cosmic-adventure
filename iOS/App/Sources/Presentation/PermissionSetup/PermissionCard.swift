//
//  PermissionCard.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PermissionCard: View {
    let iconName: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 14) {
            Image(iconName)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("blackLabel"))
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color("subBlackLabel"))
            }
            
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            Color("permissionCardBackground").opacity(0.4)
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
