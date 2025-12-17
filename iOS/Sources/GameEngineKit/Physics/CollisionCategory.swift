import Foundation

/// SpriteKit 충돌 판정을 위한 비트마스크 카테고리
public enum CollisionCategory {
    public static let none: UInt32 = 0
    public static let all: UInt32 = .max

    // 객체 정의
    public static let player: UInt32 = 1 << 0
    public static let ground: UInt32 = 1 << 1
    public static let wall: UInt32 = 1 << 2
    public static let hazard: UInt32 = 1 << 3
}
