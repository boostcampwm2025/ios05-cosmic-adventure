import Foundation

/// 매 프레임 InputSystem이 제공하는 입력 상태
public struct InputSnapshot: Equatable {
    /// 좌우 이동 의도 (-1.0: 왼쪽 최대, 0.0: 중립, 1.0: 오른쪽 최대)
    public var moveX: Double
    public var jumpTriggered: Bool
    
    public init(moveX: Double, jumpTriggered: Bool) {
        self.moveX = moveX
        self.jumpTriggered = jumpTriggered
    }
    
    public static let idle = InputSnapshot(moveX: 0, jumpTriggered: false)
}
