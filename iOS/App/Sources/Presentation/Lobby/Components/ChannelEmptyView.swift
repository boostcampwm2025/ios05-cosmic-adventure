//
//  ChannelEmptyView.swift
//  App
//
//  Created by Cursor on 1/28/26.
//

import SwiftUI

struct ChannelEmptyView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppAsset.Image.speechBubble.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 44)
                
                VStack(spacing: 6) {
                    Text(L10N.Lobby.emptyGalaxyTitle)
                        .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 23))
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                    
                    Text(L10N.Lobby.emptyGalaxySubtitle)
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 16))
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 49)
            }
            
            AppAsset.Image.character1Sad.swiftUIImage
                .resizable()
                .frame(width: 88, height: 106)
                .padding(.top, -30)
        }
        .padding(.top, 30)
    }
}

#Preview {
    ZStack {
        ChannelEmptyView()
    }
}
