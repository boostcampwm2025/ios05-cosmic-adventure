//
//  LobbyModels.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

// MARK: - Explorer Role

enum ExplorerRole: Equatable {
    case me
    case peer
}

// MARK: - Lobby Explorer

struct LobbyExplorer: Identifiable, Equatable, Hashable {
    let id: String
    let role: ExplorerRole
    let displayName: String
    let avatar: CharacterAvatar
    
    /// 수신 감도/근접도: 0.0~1.0, 값이 클수록 내 위치에 더 가까움
    /// - nil이면 아직 미측정/알 수 없음
    /// - peer만 의미 있음 (me는 항상 중앙 고정)
    var proximity: Double?
    
    init(
        id: String? = nil,
        role: ExplorerRole,
        displayName: String,
        avatar: CharacterAvatar,
        proximity: Double? = nil
    ) {
        self.id = id ?? displayName
        self.role = role
        self.displayName = displayName
        self.avatar = avatar
        self.proximity = proximity
    }
}

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
        case .orbit1Top, .orbit1Bottom: 0.28
        case .orbit2LeftTop, .orbit2RightTop, .orbit2LeftBottom, .orbit2RightBottom: 0.38
        case .orbit3LeftTop, .orbit3RightTop, .orbit3LeftBottom, .orbit3RightBottom: 0.48
        }
    }
    
    static var orderedSlots: [OrbitSlot] {
        [.orbit1Top, .orbit1Bottom, .orbit2LeftTop, .orbit2RightTop, .orbit2LeftBottom, .orbit2RightBottom, .orbit3LeftTop, .orbit3RightTop, .orbit3LeftBottom, .orbit3RightBottom]
    }
}

enum LobbyAlert {
    case none
    case permissionDenied
    case unknownNetworkError

    var title: LocalizedStringKey {
        switch self {
        case .permissionDenied: return L10N.Common.permissionAlertTitle
        case .unknownNetworkError: return L10N.Alert.defaultTitle
        case .none: return ""
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .permissionDenied:
            return L10N.Alert.localNetworkSubTitle
        case .unknownNetworkError:
            return L10N.Alert.unknownSubTitle
        case .none:
            return ""
        }
    }

    var primaryButtonTitle: LocalizedStringKey {
        switch self {
        case .permissionDenied: return L10N.Common.goToSettings
        case .unknownNetworkError: return L10N.Common.confirm
        case .none: return ""
        }
    }
    
    var hasCancelButton: Bool {
        return self == .permissionDenied
    }
}
