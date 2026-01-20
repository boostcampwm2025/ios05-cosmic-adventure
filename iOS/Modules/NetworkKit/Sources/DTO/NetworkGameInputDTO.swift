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
        /// 로컬에서 검증 완료된 "점프/리스폰 확정 이벤트"
        case jumpTriggered
        case respawnRequested
    }

    public var kind: Kind
    public var x: Double?

    // respawn
    public var reason: Int?
    public var respawnX: Double?
    public var respawnY: Double?

    public init(kind: Kind, x: Double? = nil) {
        self.kind = kind
        self.x = x
    }

    public static func horizontal(_ x: Double) -> Self {
        .init(kind: .horizontal, x: x)
    }

    public static var jumpTriggered: Self {
        .init(kind: .jumpTriggered, x: nil)
    }
    
    public static func respawnRequested(reason: Int, x: Double, y: Double) -> Self {
        var dto = Self(kind: .respawnRequested)
        dto.reason = reason
        dto.respawnX = x
        dto.respawnY = y
        return dto
    }
}
