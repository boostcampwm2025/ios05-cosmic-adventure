//
//  NetworkGameInputDTO.swift
//  NetworkKit
//
//  Created by sungkug_apple_developer_ac on 1/19/26.
//

// MARK: - DTOs

/// 게임 입력 전송용 DTO
public struct NetworkGameInputDTO: Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case horizontal
        case jump
    }

    public var kind: Kind
    public var x: Double?

    public init(kind: Kind, x: Double? = nil) {
        self.kind = kind
        self.x = x
    }

    public static func horizontal(_ x: Double) -> Self {
        .init(kind: .horizontal, x: x)
    }

    public static var jump: Self {
        .init(kind: .jump, x: nil)
    }
}
