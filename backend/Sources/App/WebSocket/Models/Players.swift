//
//  Players.swift
//  backend
//
//  Created by 강윤서 on 2/5/26.
//

import Foundation

/// 플레이어 개별 정보
struct PlayerInfo: Codable {
    let sessionId: String
    let nickname: String
    let characterRawValue: String
    let latency: Double
}

/// 채널 내 플레이어 목록 응답 데이터
struct PlayerListPayload: Codable {
    let youSessionId: String
    let players: [PlayerInfo]
}
