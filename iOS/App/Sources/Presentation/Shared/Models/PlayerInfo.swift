//
//  PlayerInfo.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/7/26.
//

import Foundation

// MARK: - Player Role

enum PlayerRole: Equatable {
    case local
    case remote
}

// MARK: - Player Info

struct PlayerInfo: Identifiable, Equatable, Hashable {
    let id: UUID
    let role: PlayerRole
    let displayName: String
    let avatar: CharacterAvatar

    /// 수신 감도/근접도: 0.0~1.0, 값이 클수록 내 위치에 더 가까움
    /// - nil이면 아직 미측정/알 수 없음
    /// - remote만 의미 있음 (local는 항상 중앙 고정)
    var proximity: Double?

    init(
        id: UUID? = nil,
        role: PlayerRole,
        displayName: String,
        avatar: CharacterAvatar,
        proximity: Double? = nil
    ) {
        self.id = id ?? UUID()
        self.role = role
        self.displayName = displayName
        self.avatar = avatar
        self.proximity = proximity
    }
}
