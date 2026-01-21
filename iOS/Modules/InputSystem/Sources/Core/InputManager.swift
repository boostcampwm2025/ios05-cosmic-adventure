
import ARKit
import Foundation

public final class InputManager {
    private let hub: InputEventHub
    private let source: InputSource

    public var onFrameUpdate: ((CVPixelBuffer) -> Void)? {
        get { (source as? ARFaceTrackingInputSource)?.onFrameUpdate }
        set { (source as? ARFaceTrackingInputSource)?.onFrameUpdate = newValue }
    }

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
    struct FaceTrackingConfig {
        public let puckerThreshold: Double
        public let rollThreshold: Double
        public let maxRoll: Double
        
        public init(
            puckerThreshold: Double = InputConstants.Face.defaultPuckerThreshold,
            rollThreshold: Double = InputConstants.Face.rollThreshold,
            maxRoll: Double = InputConstants.Face.maxRoll
        ) {
            self.puckerThreshold = puckerThreshold
            self.rollThreshold = rollThreshold
            self.maxRoll = maxRoll
        }
        
        var strategy: FaceInputStrategy {
            TiltAndPuckerFaceInputStrategy(
                puckerThreshold: puckerThreshold,
                rollThreshold: rollThreshold,
                maxRoll: maxRoll
            )
        }
    }

    enum Source {
        case faceTracking(config: FaceTrackingConfig = FaceTrackingConfig())
    }

    convenience init(source: Source) {
        switch source {
        case .faceTracking(let config):
            self.init { hub in
                ARFaceTrackingInputSource(strategy: config.strategy, hub: hub)
            }
        }
    }
}
