//
//  GameConstant.swift
//  Engine
//
//  Created by 강윤서 on 12/18/25.
//

import Foundation

/// 게임엔진에서 필요한 상수값을 관리
public enum GameConstant {
    /// 동작 설정
    static public let normalJumpImpulse: CGFloat = 100
    static public let superJumpImpulse: CGFloat = 150
    static public let moveSpeed: CGFloat = 100
    
    /// 플레이어 설정
    static public let gravity: CGFloat = 9.8
    static public let playerRestitution: CGFloat = 0.2
    static public let playerFriction: CGFloat = 0.5
    
    /// 인식 감도
    static public let jumpThreshold: Float = 0.5
    static public let superJumpThreshold: Float = 0.6
    static public let tiltThreshold: Float = 0.4
    
    /// 맵 설정
    static public let brickWidth: CGFloat = 80
    static public let brickHeight: CGFloat = 20
    static public let startY: CGFloat = 300             // 블록 시작 높이
    static public let verticalGap: CGFloat = 150        // 세로 간격
    static public let numberOfLevels = 30               // 맵의 블록 수 (높게 만들기)
}
