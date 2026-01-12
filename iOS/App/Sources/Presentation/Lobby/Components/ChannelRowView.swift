//
//  ChannelRowView.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import SwiftUI

struct ChannelRowView: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                    
                    Text(channel.playerCountText)
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 12))
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor.opacity(0.6))
                }
                
                Spacer()
                
                statusBadge
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                AppAsset.Color.permissionCardBackground.swiftUIColor
                    .opacity(0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(channel.isFull)
        .opacity(channel.isFull ? 0.5 : 1.0)
    }
    
    private var statusBadge: some View {
        Text(channel.isFull ? "만원" : "입장 가능")
            .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 12))
            .foregroundStyle(channel.isFull ? .red : .green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((channel.isFull ? Color.red : Color.green).opacity(0.2))
            )
    }
}
