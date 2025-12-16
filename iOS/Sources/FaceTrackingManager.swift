//
//  FaceTrackingManager.swift
//  iOS
//
//  Created by soyoung on 12/16/25.
//

import ARKit
import Combine

class FaceTrackingManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var jawOpenValue: Float = 0.0
    @Published var mouthFunnelValue: Float = 0.0
    @Published var mouthPuckerValue: Float = 0.0
    @Published var mouthCloseValue: Float = 0.0
    @Published var cheekPuffValue: Float = 0.0

    var session = ARSession()

    override init() {
        super.init()
        setupSession()
    }

    func setupSession() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        session.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }

        // 값 추출
        let jawOpen = faceAnchor.blendShapes[.jawOpen]?.floatValue ?? 0.0
        let funnel = faceAnchor.blendShapes[.mouthFunnel]?.floatValue ?? 0.0
        let pucker = faceAnchor.blendShapes[.mouthPucker]?.floatValue ?? 0.0
        let close = faceAnchor.blendShapes[.mouthClose]?.floatValue ?? 0.0
        let puff = faceAnchor.blendShapes[.cheekPuff]?.floatValue ?? 0.0

        DispatchQueue.main.async {
            self.jawOpenValue = jawOpen
            self.mouthFunnelValue = funnel
            self.mouthPuckerValue = pucker
            self.mouthCloseValue = close
            self.cheekPuffValue = puff
        }
    }
}
