//
//  ARFaceTrackingInputSource.swift
//  InputSystem
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import ARKit
import Foundation

final class ARFaceTrackingInputSource: NSObject, InputSource, ARSessionPreviewProviding {
    private let session: ARSession
    private let strategy: FaceInputStrategy
    private let hub: InputEventHub

    init(
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

    func start() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }

    func previewSession() -> ARSession {
        session
    }
}

extension ARFaceTrackingInputSource: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for faceAnchor in anchors.compactMap({ $0 as? ARFaceAnchor }) {
            let events = strategy.interpret(anchor: faceAnchor)
            for event in events {
                Task { await hub.yield(event) }
            }
        }
    }
}
