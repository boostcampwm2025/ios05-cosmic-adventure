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
    public var positionX: Double?
    public var positionY: Double?
    public var jumpSeq: Int?

    // respawn
    public var reason: Int?
    public var respawnX: Double?
    public var respawnY: Double?

    public init(
        kind: Kind,
        x: Double? = nil,
        positionX: Double? = nil,
        positionY: Double? = nil
    ) {
        self.kind = kind
        self.x = x
        self.positionX = positionX
        self.positionY = positionY
    }

    public static func horizontal(_ x: Double, positionX: Double? = nil, positionY: Double? = nil) -> Self {
        .init(kind: .horizontal, x: x, positionX: positionX, positionY: positionY)
    }

    public static var jumpTriggered: Self {
        .init(kind: .jumpTriggered, x: nil)
    }

    public static func jumpTriggered(
        moveX: Double,
        positionX: Double,
        positionY: Double,
        jumpSeq: Int
    ) -> Self {
        var dto = Self(
            kind: .jumpTriggered,
            x: moveX,
            positionX: positionX,
            positionY: positionY
        )
        dto.jumpSeq = jumpSeq
        return dto
    }
    
    public static func respawnRequested(reason: Int, x: Double, y: Double) -> Self {
        var dto = Self(kind: .respawnRequested)
        dto.reason = reason
        dto.respawnX = x
        dto.respawnY = y
        return dto
    }
}
