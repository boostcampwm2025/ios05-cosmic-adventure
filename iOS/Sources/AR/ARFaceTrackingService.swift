//
//  ARFaceTrackingService.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import ARKit

final class ARFaceTrackingService: NSObject {
    
    private let session: ARSession
    
    override init() {
        self.session = ARSession()
        super.init()
        session.delegate = self
    }
    
    func start() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // 기존 세션에 남아 있던 트래킹 상태/ anchor 초기화
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stop() {
        session.pause()
    }
}

extension ARFaceTrackingService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARFaceAnchor }) {
            let browRaise = anchor.blendShapes[.mouthPucker]?.floatValue ?? 0 > 0.5
        }
    }
}
