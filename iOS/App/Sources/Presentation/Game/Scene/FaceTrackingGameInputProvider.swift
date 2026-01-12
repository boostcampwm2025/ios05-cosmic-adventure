//
//  FaceTrackingGameInputProvider.swift
//  App
//
//  Created by 영빈 on 1/8/26.
//

import ARKit
import Games
import InputSystem

public final class FaceTrackingGameInputProvider: GameInputProviding, @unchecked Sendable {
    private let inputManager: InputManager

    public init() {
        self.inputManager = InputManager(source: .faceTracking())
    }

    public func start() {
        inputManager.start()
    }

    public func stop() {
        inputManager.stop()
    }

    public func events() async -> AsyncStream<GameInputEvent> {
        let rawStream = await inputManager.events()

        return AsyncStream { continuation in
            let task = Task {
                for await event in rawStream {
                    switch event {
                    case .horizontal(let x):
                        continuation.yield(.horizontal(x))
                    case .action(.jump, let value):
                        continuation.yield(.jump(isActive: value > 0.5))
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

extension FaceTrackingGameInputProvider {
    func previewSession() -> ARSession? {
        inputManager.previewSession()
    }
}
