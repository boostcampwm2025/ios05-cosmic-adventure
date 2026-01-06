//
//  BackgroundContainerView.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

struct BackgroundContainerView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppAsset.Image.background.swiftUIImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                content
            }
        }
        .ignoresSafeArea()
    }
}
