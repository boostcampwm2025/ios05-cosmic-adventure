//
//  NetworkGameEndDTO.swift
//  NetworkKit
//
//  Created by sungkug_apple_developer_ac on 1/27/26.
//

public struct NetworkGameEndDTO: Codable, Sendable {
    public let reason: Int

    public init(reason: Int) {
        self.reason = reason
    }
}
