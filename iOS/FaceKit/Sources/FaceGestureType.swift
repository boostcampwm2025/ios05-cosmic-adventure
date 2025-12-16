//
//  FaceGestureType.swift
//  FaceKit
//
//  Created by 강윤서 on 12/17/25.
//

import Foundation

enum FaceGestureType: Equatable {
    case jump                   // 뽀뽀
    case superJump              // 볼에 바람 넣기
    case move(MoveDirect)       // 고개 갸웃
    case none                   // 기본 상태
}

enum MoveDirect {
    case left
    case right
}

struct FaceGestureState {
    let gestureType: FaceGestureType
    let intensity: Float  // 0.0~1.0
    let timestamp: Date
}
