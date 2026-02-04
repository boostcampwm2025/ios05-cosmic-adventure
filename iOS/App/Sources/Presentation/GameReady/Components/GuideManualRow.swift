//
//  GuideManualRow.swift
//  App
//
//  Created by 영빈 on 1/23/26.
//

import SwiftUI

struct GuideManualRow: View {
    let characterImage: Image?
    let manualText: LocalizedStringKey
    let subText: LocalizedStringKey?
    
    init(
        characterImage: Image? = nil,
        manualText: LocalizedStringKey,
        subText: LocalizedStringKey? = nil
    ) {
        self.characterImage = characterImage
        self.manualText = manualText
        self.subText = subText
    }
    
    var body: some View {
        if let characterImage {
            HStack(alignment: .center, spacing: 27) {
                characterImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 67)
                    .padding(.leading, 67)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(manualText)
                        .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                        .foregroundColor(.white)
                        .padding(.top, subText == nil ? 9 : 8)
                    
                    if let subText {
                        Text(subText)
                            .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 13))
                            .foregroundColor(.white)
                    }
                }
            }
        } else {
            VStack(spacing: 2) {
                Text(manualText)
                    .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let subText {
                    Text(subText)
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview("With Image") {
    ZStack {
        Color.black.ignoresSafeArea()
        GuideManualRow(
            characterImage: AppAsset.Image.character1.swiftUIImage,
            manualText: "고개를 좌우로 갸웃거리면\n앞으로 움직여요."
        )
    }
}

#Preview("Without Image") {
    ZStack {
        Color.black.ignoresSafeArea()
        GuideManualRow(
            manualText: "제한 시간 1분 안에 결승점에 도착하세요."
        )
    }
}
#endif
