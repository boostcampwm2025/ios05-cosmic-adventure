//
//  SettingsToggleRow.swift
//  App
//
//  Created by 영빈 on 1/21/26.
//

import SwiftUI

struct SettingsToggleRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 18))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppAsset.Color.buttonGradientEnd.swiftUIColor)
        }
    }
}
