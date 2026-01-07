//
//  MathUtils.swift
//  GameEngineCore
//
//  Created by soyoung on 1/7/26.
//

import CoreGraphics

public extension CGFloat {
    // 선형 보간 (Linear Interpolation)
    static func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }
}
