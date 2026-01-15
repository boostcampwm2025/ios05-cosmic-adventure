//
//  GuideImageView.swift
//  App
//
//  Created by AI on 1/15/26.
//

import SwiftUI

struct GuideImageView: View {
    let image: Image?
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
            } else {
                Color.clear
                    .frame(height: 160)
            }
        }
    }
}
