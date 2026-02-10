//
//  UIConstants.swift
//  App
//
//  Created by 강윤서 on 2/10/26.
//

import SwiftUI

enum Metrics {
    private static var currentWindowScene: UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
    }

    private static var screenBounds: CGRect {
        return currentWindowScene?.screen.bounds ?? .zero
    }
    
    // 화면 전체 사이즈 관련 (호출 시점에 계산)
    static var screenSize: CGSize { screenBounds.size }
    static var screenWidth: CGFloat { screenBounds.width }
    static var screenHeight: CGFloat { screenBounds.height }
}
