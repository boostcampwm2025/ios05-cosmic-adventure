//
//  InputEventHub.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import Foundation

public actor InputEventHub {
    private var continuations: [UUID: AsyncStream<InputEvent>.Continuation] = [:]

    public init() {}

    /// 구독자마다 새 스트림을 만들어 등록(멀티 구독 가능)
    public func makeStream(
        bufferingPolicy: AsyncStream<InputEvent>.Continuation.BufferingPolicy = .bufferingNewest(120)
    ) -> AsyncStream<InputEvent> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID()
            continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task { await self?.remove(id: id) }
            }
        }
    }

    /// 이벤트 발행(모든 구독자에게 전달)
    public func yield(_ event: InputEvent) {
        for (_, cont) in continuations {
            cont.yield(event)
        }
    }

    private func remove(id: UUID) {
        continuations[id] = nil
    }
}
