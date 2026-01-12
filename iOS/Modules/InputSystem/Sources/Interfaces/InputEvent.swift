//
//  InputEvent.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

public enum InputAction: Sendable, Equatable {
    case jump
    case custom(String)
}

public enum InputEvent: Sendable, Equatable {
    /// -1.0 ~ +1.0 권장 (왼쪽 음수, 오른쪽 양수)
    case horizontal(Double)

    /// 0.0 ~ 1.0 권장 (점프 강도 등)
    case action(InputAction, value: Double)
}
