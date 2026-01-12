
import ARKit
import Foundation

public final class InputManager {
    private let hub: InputEventHub
    private let source: InputSource

    public init(makeSource: (InputEventHub) -> InputSource) {
        let hub = InputEventHub()
        self.hub = hub
        self.source = makeSource(hub)
    }

    public func start() { source.start() }
    public func stop() { source.stop() }

    public func events() async -> AsyncStream<InputEvent> {
        await hub.makeStream()
    }
    
    public func previewSession() -> ARSession? {
        (source as? ARSessionPreviewProviding)?.previewSession()
    }
}

public extension InputManager {
    enum FaceTrackingStrategyOption {
        case tiltAndPucker(puckerThreshold: Double = InputConstants.Face.defaultPuckerThreshold)
        case custom(FaceInputStrategy)

        var strategy: FaceInputStrategy {
            switch self {
            case .tiltAndPucker(let threshold):
                return TiltAndPuckerFaceInputStrategy(puckerThreshold: threshold)
            case .custom(let s):
                return s
            }
        }
    }

    enum Source {
        case faceTracking(strategy: FaceTrackingStrategyOption = .tiltAndPucker())
    }

    convenience init(source: Source) {
        switch source {
        case .faceTracking(let option):
            self.init { hub in
                ARFaceTrackingInputSource(strategy: option.strategy, hub: hub)
            }
        }
    }
}
