import CoreGraphics

/// 물리 시스템 튜닝 상수
public enum PhysicsConstants {
    // MARK: - 이동

    public static let moveSpeed: CGFloat = 340.0 // 최대 이동 속도

    /// 지상 가속 계수 (높을수록 빠른 반응)
    public static let groundAcceleration: CGFloat = 0.4
    /// 지상 감속 계수 (입력 없을 때, 높을수록 빠른 정지)
    public static let groundDeceleration: CGFloat = 0.25

    /// 공중 가속 계수 (지상보다 낮아서 관성 있음)
    public static let airAcceleration: CGFloat = 0.08
    /// 공중 감속 계수 (입력 없을 때)
    public static let airDeceleration: CGFloat = 0.04

    // MARK: - 점프

    public static let jumpImpulse: CGFloat = 65.0 // 점프 힘

    /// Apex(점프 정점) 판정 속도 임계값
    public static let apexThreshold: CGFloat = 50.0
    /// Apex에서 중력 배율 (1.0 미만 = 체공감)
    public static let apexGravityMultiplier: CGFloat = 0.5
    /// 하강 시 중력 배율 (1.0 초과 = 빠른 낙하)
    public static let fallGravityMultiplier: CGFloat = 1.3

    // MARK: - 물리 환경

    public static let gravityDY: CGFloat = -15.0 // 기본 중력
    public static let linearDamping: CGFloat = 0.5 // 공기 저항 (낮춤)
    public static let friction: CGFloat = 0.2 // 마찰력
    public static let restitution: CGFloat = 0.0 // 탄성 계수 (0=튀지 않음)
}
