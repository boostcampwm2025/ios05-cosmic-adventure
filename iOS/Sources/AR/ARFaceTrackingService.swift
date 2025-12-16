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
}

extension ARFaceTrackingService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARFaceAnchor }) {
            let browRaise = anchor.blendShapes[.mouthPucker]?.floatValue ?? 0 > 0.5
        }
    }
}
