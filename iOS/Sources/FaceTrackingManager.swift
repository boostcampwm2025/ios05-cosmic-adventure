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
    @Published var headRoll: Float = 0.0

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
        let roll = faceAnchor.transform.eulerAngles.z

        DispatchQueue.main.async {
            self.jawOpenValue = jawOpen
            self.mouthFunnelValue = funnel
            self.mouthPuckerValue = pucker
            self.mouthCloseValue = close
            self.cheekPuffValue = puff
            self.headRoll = -roll
        }
    }
}

extension simd_float4x4 {
    var eulerAngles: SIMD3<Float> {
        return SIMD3<Float>(
            asin(-columns.2.y),
            atan2(columns.2.x, columns.2.z),
            atan2(columns.0.y, columns.1.y)
        )
    }
}
