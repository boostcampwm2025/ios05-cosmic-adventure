//
//  NetworkGameStartSyncDTO.swift
//  NetworkKit
//
//  Created by sungkug_apple_developer_ac on 2/3/26.
//

import Foundation

public struct NetworkGameStartSyncDTO: Codable, Sendable {
    public let startAt: TimeInterval

    // TODO: 맵 타입 보내도록 확장하기
    public init(startAt: TimeInterval) {
        self.startAt = startAt
    }
}
