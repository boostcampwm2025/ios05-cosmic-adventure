//
//  BackgroundContainerView.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

struct BackgroundContainerView<Content: View>: View {
    let respectsSafeArea: Bool
    let content: Content
    
    init(respectsSafeArea: Bool = false, @ViewBuilder content: () -> Content) {
        self.respectsSafeArea = respectsSafeArea
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                AppAsset.Image.background.swiftUIImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            
            content
        }
        .ignoresSafeArea(respectsSafeArea ? [] : .all)
    }
}
