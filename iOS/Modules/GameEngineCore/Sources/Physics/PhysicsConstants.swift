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
    public static let inputThreshold: CGFloat = 0.01
    public static let groundAcceleration: CGFloat = 0.4
    public static let groundDeceleration: CGFloat = 0.25
    public static let airAcceleration: CGFloat = 0.08
    public static let airDeceleration: CGFloat = 0.04

    // 점프
    public static let jumpImpulse: CGFloat = 65.0

    // 중력 보정 (Apex Control)
    public static let apexThreshold: CGFloat = 50.0
    public static let apexGravityMultiplier: CGFloat = 0.5
    public static let fallGravityMultiplier: CGFloat = 1.3

    // 환경
    public static let gravityDY: CGFloat = -9.8
    public static let linearDamping: CGFloat = 2.0
    public static let friction: CGFloat = 1.0
    public static let restitution: CGFloat = 0.0
}
