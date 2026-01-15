//
//  CheckButton.swift
//  App
//
//  Created by AI on 1/15/26.
//

import SwiftUI

struct CheckButton: View {
    @Binding var isChecked: Bool
    let title: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 9) {
            Button(action: { isChecked.toggle() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isChecked {
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
    ZStack {
        Color.black.ignoresSafeArea()
        CheckButton(isChecked: .constant(true), title: "다시 보지 않기")
    }
}
