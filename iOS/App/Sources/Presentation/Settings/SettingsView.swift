//
//  SettingsView.swift
//  App
//
//  Created by 영빈 on 1/21/26.
//

import SwiftUI

struct SettingsView: View {
    init() {
    }
    
    var body: some View {
        BackgroundContainerView {
            ScrollView {
                VStack(spacing: 32) {
                }
                .padding(.horizontal, 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
