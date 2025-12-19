import CoreGraphics
import Foundation

/// 선형 보간 (Linear Interpolation)
/// - Parameters:
///   - start: 시작 값
///   - end: 목표 값
///   - t: 진행 비율 (0.0 ~ 1.0)
public func lerp<T: FloatingPoint>(_ start: T, _ end: T, _ t: T) -> T {
    return start + (end - start) * t
}
