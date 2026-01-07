//
//  FaceTrackingGameInputProvider.swift
//  App
//
//  Created by 영빈 on 1/8/26.
//

import Games
import InputSystem

public final class FaceTrackingGameInputProvider: GameInputProviding, @unchecked Sendable {
    private let inputSystem: InputSystem

    public init() {
        self.inputSystem = InputSystem(source: .faceTracking())
    }

    public func start() {
        inputSystem.start()
    }

    public func stop() {
        inputSystem.stop()
    }

    public func events() async -> AsyncStream<GameInputEvent> {
        let rawStream = await inputSystem.events()

        return AsyncStream { continuation in
            let task = Task {
                for await event in rawStream {
                    switch event {
                    case .horizontal(let x):
                        continuation.yield(.horizontal(x))
                    case .action(.primary, _):
                        continuation.yield(.jump)
                    case .action:
                        break
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
