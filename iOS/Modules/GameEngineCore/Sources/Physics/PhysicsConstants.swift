//
//  PhysicsConstants.swift
//  GameEngineCore
//
//  Created by soyoung on 1/7/26.
//

import CoreGraphics

public enum PhysicsConstants {
    // 이동
    public static let moveSpeed: CGFloat = 340.0
    public static let inputThreshold: CGFloat = 0.15
    public static let inputCurveExponent: CGFloat = 0.7
    public static let groundAcceleration: CGFloat = 0.4
    public static let groundDeceleration: CGFloat = 0.2
    public static let groundTurnAcceleration: CGFloat = 0.7
    public static let airAcceleration: CGFloat = 0.08
    public static let airDeceleration: CGFloat = 0.005
    public static let airTurnAcceleration: CGFloat = 0.12

    // 점프
    public static let jumpImpulse: CGFloat = 100.0

    // 중력 보정 (Apex Control)
    public static let apexThreshold: CGFloat = 30.0
    public static let apexGravityMultiplier: CGFloat = 0.85
    public static let fallGravityMultiplier: CGFloat = 1.3

    // 환경
    public static let gravityDY: CGFloat = -12.0
    public static let linearDamping: CGFloat = 0.5
    public static let friction: CGFloat = 1.0
    public static let restitution: CGFloat = 0.0
}
