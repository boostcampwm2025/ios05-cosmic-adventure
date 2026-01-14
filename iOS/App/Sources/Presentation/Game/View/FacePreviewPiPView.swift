//
//  FacePreviewPIPView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/14/26.
//

import SwiftUI

public struct FacePreviewPIPView<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let defaultPadding = 25
            let containerSize = proxy.size
            let pipSize = CGSize(width: 140, height: 180)
            let defaultCenter = CGPoint(
                x: containerSize.width - pipSize.width / 2 - 20,
                y: containerSize.height - pipSize.height / 2 - 20
            )

            content
                .frame(width: pipSize.width, height: pipSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(radius: 6)
                .position(defaultCenter)
        }
        .ignoresSafeArea()
    }
}
