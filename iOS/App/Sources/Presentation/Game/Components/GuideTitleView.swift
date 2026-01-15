//
//  GuideTitleView.swift
//  App
//
//  Created by AI on 1/15/26.
//

import SwiftUI

struct GuideTitleView: View {
    let title: LocalizedStringKey
    var leadingPadding: CGFloat = 39
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 32))
                .foregroundColor(.white)
                .padding(.top, 41)
                .padding(.leading, leadingPadding)
        }
    }
}
