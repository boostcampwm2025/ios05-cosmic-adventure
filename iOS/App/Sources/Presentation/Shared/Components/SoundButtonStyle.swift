//
//  SoundButtonStyle.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 2/5/26.
//


import SwiftUI

struct SoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    AudioManager.shared.playSFX(.buttonTap)
                }
            }
    }
}
