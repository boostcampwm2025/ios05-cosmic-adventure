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

struct LobbyExplorer: Identifiable, Equatable {
    let id: UUID
    let role: ExplorerRole
    let displayName: String
    let avatar: CharacterAvatar
    
    /// 수신 감도/근접도: 0.0~1.0, 값이 클수록 내 위치에 더 가까움
    /// - nil이면 아직 미측정/알 수 없음
    /// - peer만 의미 있음 (me는 항상 중앙 고정)
    var proximity: Double?
    
    init(
        id: UUID = UUID(),
        role: ExplorerRole,
        displayName: String,
        avatar: CharacterAvatar,
        proximity: Double? = nil
    ) {
        self.id = id
        self.role = role
        self.displayName = displayName
        self.avatar = avatar
        self.proximity = proximity
    }
}

// MARK: - Orbit Layout

enum OrbitSlot: CaseIterable {
    case orbit1Top
    case orbit2LeftTop
    case orbit2RightTop
    case orbit3LeftBottom
    case orbit3RightBottom
    
    var angleDegrees: Double {
        switch self {
        case .orbit1Top: 270
        case .orbit2LeftTop: 225
        case .orbit2RightTop: 315
        case .orbit3LeftBottom: 135
        case .orbit3RightBottom: 45
        }
    }
    
    var radiusFactor: CGFloat {
        switch self {
        case .orbit1Top: 0.28
        case .orbit2LeftTop, .orbit2RightTop: 0.38
        case .orbit3LeftBottom, .orbit3RightBottom: 0.48
        }
    }
    
    static var orderedSlots: [OrbitSlot] {
        [.orbit1Top, .orbit2LeftTop, .orbit2RightTop, .orbit3LeftBottom, .orbit3RightBottom]
    }
}
