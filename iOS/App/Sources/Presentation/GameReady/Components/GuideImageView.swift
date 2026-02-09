//
//  GuideImageView.swift
//  App
//
//  Created by AI on 1/15/26.
//

import SwiftUI

struct GuideImageView: View {
    let image: Image?
    let imageSize: CGFloat?

    var body: some View {
        Group {
            if let image = image, let imageSize = imageSize {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: imageSize)
            } else {
                Color.clear
                    .frame(height: imageSize)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
