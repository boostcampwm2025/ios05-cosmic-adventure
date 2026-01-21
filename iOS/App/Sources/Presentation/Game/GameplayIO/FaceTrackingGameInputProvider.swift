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

    public init(
        jumpSensitivity: SettingsLevel = .medium,
        tiltSensitivity: SettingsLevel = .medium
    ) {
        let config = Self.makeConfig(
            jumpSensitivity: jumpSensitivity,
            tiltSensitivity: tiltSensitivity
        )
        self.inputManager = InputManager(source: .faceTracking(config: config))
    }
    
    private static func makeConfig(
        jumpSensitivity: SettingsLevel,
        tiltSensitivity: SettingsLevel
    ) -> InputManager.FaceTrackingConfig {
        let puckerThreshold: Double = {
            switch jumpSensitivity {
            case .low: return 0.6
            case .medium: return 0.5
            case .high: return 0.35
            }
        }()
        
        let (rollThreshold, maxRoll): (Double, Double) = {
            switch tiltSensitivity {
            case .low: return (0.2, 1.0)
            case .medium: return (0.15, 0.9)
            case .high: return (0.1, 0.7)
            }
        }()
        
        return InputManager.FaceTrackingConfig(
            puckerThreshold: puckerThreshold,
            rollThreshold: rollThreshold,
            maxRoll: maxRoll
        )
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
