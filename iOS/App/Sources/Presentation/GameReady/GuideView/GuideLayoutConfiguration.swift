//
//  GuideLayoutConfiguration.swift
//  App
//
//  Created by soyoung on 2/9/26.
//

import Foundation

enum GuideLayoutConfiguration {
    // 비율 설정
    static let imageRatio: CGFloat = 0.2
    static let iconRatio: CGFloat = 0.08
    static let paddingRatio: CGFloat = 0.07

    // 최대 크기 제한
    static let imageMaxHeight: CGFloat = 160
    static let iconMaxSize: CGFloat = 65
    static let paddingMax: CGFloat = 58

    // Helper
    static func imageSize(for screenHeight: CGFloat) -> CGFloat {
        min(imageMaxHeight, screenHeight * imageRatio)
    }

    static func iconSize(for screenHeight: CGFloat) -> CGFloat {
        min(iconMaxSize, screenHeight * iconRatio)
    }

    static func horizontalPadding(for screenHeight: CGFloat) -> CGFloat {
        min(paddingMax, screenHeight * paddingRatio)
    }
}
