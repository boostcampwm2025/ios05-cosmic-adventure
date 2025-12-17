//
//  GameConstant.swift
//  Engine
//
//  Created by 강윤서 on 12/18/25.
//

import Foundation

/// 게임엔진에서 필요한 상수값을 관리
enum GameConstant {
    /// 동작 설정
    static let normalJumpImpulse: CGFloat = 100
    static let superJumpImpulse: CGFloat = 200
    static let moveSpeed: CGFloat = 200
    
    /// 플레이어 설정
    static let gravity: CGFloat = 9.8
    static let playerRestitution: CGFloat = 0.2
    static let playerFriction: CGFloat = 0.5
    
    /// 인식 감도
    static let jumpThreshold: Float = 0.5
    static let superJumpThreshold: Float = 0.6
    static let tiltThreshold: Float = 0.4
}
