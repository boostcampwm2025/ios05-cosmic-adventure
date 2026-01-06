//
//  ARFaceTrackingInputSource.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import ARKit
import Foundation

public final class ARFaceTrackingInputSource: NSObject, InputSource {
    private let session: ARSession
    private let strategy: FaceInputStrategy
    private let hub: InputEventHub

    public init(
        strategy: FaceInputStrategy,
        hub: InputEventHub,
        session: ARSession = ARSession()
    ) {
        self.strategy = strategy
        self.hub = hub
        self.session = session
        super.init()
        self.session.delegate = self
    }

    public func start() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    public func stop() {
        session.pause()
    }

    public func previewSession() -> ARSession {
        session
    }
}

extension ARFaceTrackingInputSource: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for faceAnchor in anchors.compactMap({ $0 as? ARFaceAnchor }) {
            let events = strategy.interpret(anchor: faceAnchor)
            for event in events {
                Task { await hub.yield(event) }
            }
        }
    }
}
