//
//  SettingsSliderLabelRow.swift
//  App
//
//  Created by 영빈 on 1/22/26.
//

import SwiftUI

struct SettingsSliderLabelRow: View {
    let labels: [LocalizedStringKey]
    var textColor: Color = AppAsset.Color.mainLabel.swiftUIColor
    
    var body: some View {
        HStack {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 14))
                    .foregroundStyle(textColor.opacity(0.8))
                
                if index < labels.count - 1 {
                    Spacer()
                }
            }
        }
    }
}
