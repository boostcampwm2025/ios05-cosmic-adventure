//
//  InputEvent.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

public enum InputAction: Sendable, Equatable {
    case primary      // jump
    case custom(String) // 나중에 Action 추가할 수 있도록 분리
}

public enum InputEvent: Sendable, Equatable {
    /// -1.0 ~ +1.0 권장 (왼쪽 음수, 오른쪽 양수)
    case horizontal(Double)

    /// 0.0 ~ 1.0 권장 (점프 강도 등)
    case action(InputAction, value: Double)
}
