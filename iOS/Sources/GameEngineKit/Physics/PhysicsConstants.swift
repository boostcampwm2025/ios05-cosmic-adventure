import CoreGraphics

/// 물리 시스템 튜닝 상수
public enum PhysicsConstants {
    // 이동
    public static let moveSpeed: CGFloat = 340.0 // 최대 이동 속도
    public static let acceleration: CGFloat = 20.0 // 가속감
    public static let movementSmoothing: CGFloat = 0.12 // 이동 lerp 보간 계수 (클수록 빠른 반응)

    // 점프
    public static let jumpImpulse: CGFloat = 65.0 // 1단 점프 힘

    // 물리 환경
    public static let gravityDY: CGFloat = -15.0 // 계수가 높아지면 더 빠르게 떨어짐
    public static let linearDamping: CGFloat = 1.0 // 공기 저항
    public static let friction: CGFloat = 0.2 // 마찰력
    public static let restitution: CGFloat = 0.0 // 탄성 계수 (0=튀지 않음)
}
