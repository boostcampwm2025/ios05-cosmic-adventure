//
//  FaceTrackingGameInputProvider.swift
//  App
//
//  Created by 영빈 on 1/8/26.
//

import ARKit
import Games
import InputSystem

final class FaceTrackingGameInputProvider: GameInputProviding, @unchecked Sendable {
    private let inputManager: InputManager

    var onFrameUpdate: ((CVPixelBuffer) -> Void)? {
        get { inputManager.onFrameUpdate }
        set { inputManager.onFrameUpdate = newValue }
    }

    init() {
        self.inputManager = InputManager(source: .faceTracking())
    }

    func start() {
        inputManager.start()
    }

    func stop() {
        inputManager.stop()
    }

    func events() async -> AsyncStream<GameInputEvent> {
        let rawStream = await inputManager.events()

        return AsyncStream { continuation in
            let task = Task {
                for await event in rawStream {
                    switch event {
                    case .horizontal(let x):
                        continuation.yield(.horizontal(x))
                    case .action(.jump, _):
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

extension FaceTrackingGameInputProvider {
    func previewSession() -> ARSession? {
        inputManager.previewSession()
    }
}
