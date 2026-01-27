//
//  LobbyModels.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

// MARK: - Orbit Layout

enum OrbitSlot: CaseIterable {
    case orbit1Top
    case orbit1Bottom
    case orbit2LeftTop
    case orbit2RightTop
    case orbit2LeftBottom
    case orbit2RightBottom
    case orbit3LeftTop
    case orbit3RightTop
    case orbit3LeftBottom
    case orbit3RightBottom

    // MARK: - Orbit Radius Constants

    static let orbit1Radius: CGFloat = 0.28
    static let orbit2Radius: CGFloat = 0.38
    static let orbit3Radius: CGFloat = 0.48

    // MARK: - Proximity Constants

    static let proximityNearThreshold: Double = 0.33
    static let proximityFarThreshold: Double = 0.66
    static let defaultProximity: Double = 0.5
    static let zoomOutScale: CGFloat = 1.25

    // MARK: - Computed Properties

    var angleDegrees: Double {
        switch self {
        case .orbit1Top: 270
        case .orbit1Bottom: 90
        case .orbit2LeftTop: 225
        case .orbit2RightTop: 315
        case .orbit2LeftBottom: 135
        case .orbit2RightBottom: 45
        case .orbit3LeftTop: 200
        case .orbit3RightTop: 340
        case .orbit3LeftBottom: 160
        case .orbit3RightBottom: 20
        }
    }

    var radiusFactor: CGFloat {
        switch self {
        case .orbit1Top, .orbit1Bottom: Self.orbit1Radius
        case .orbit2LeftTop, .orbit2RightTop, .orbit2LeftBottom, .orbit2RightBottom: Self.orbit2Radius
        case .orbit3LeftTop, .orbit3RightTop, .orbit3LeftBottom, .orbit3RightBottom: Self.orbit3Radius
        }
    }

    static var orderedSlots: [OrbitSlot] {
        [.orbit1Top, .orbit1Bottom, .orbit2LeftTop, .orbit2RightTop, .orbit2LeftBottom, .orbit2RightBottom, .orbit3LeftTop, .orbit3RightTop, .orbit3LeftBottom, .orbit3RightBottom]
    }
}
