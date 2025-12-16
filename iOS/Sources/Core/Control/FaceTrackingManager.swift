import ARKit
import Combine

class FaceTrackingManager: NSObject, ObservableObject, ARSessionDelegate {
    var arSession: ARSession

    @Published var blendShapes: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    @Published var headTransform: simd_float4x4?

    /// ARSession 업데이트마다 증가 (SwiftUI onChange 트리거용)
    @Published var updateCounter: UInt64 = 0

    override init() {
        arSession = ARSession()
        super.init()
        arSession.delegate = self
    }

    func startTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device")
            return
        }

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false

        // 기존 세션 옵션 초기화
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stopTracking() {
        arSession.pause()
    }

    // MARK: - ARSessionDelegate

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }

        // 주요 BlendShape만 추출
        // ARKit의 blendShapes 값은 NSNumber로 들어오므로 Float 변환이 필요
        var newBlendShapes: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
        let keys: [ARFaceAnchor.BlendShapeLocation] = [.mouthPucker]

        for key in keys {
            if let number = faceAnchor.blendShapes[key] {
                newBlendShapes[key] = number.floatValue
            }
        }

        DispatchQueue.main.async {
            self.blendShapes = newBlendShapes
            self.headTransform = faceAnchor.transform
            self.updateCounter &+= 1
        }
    }

    func session(_: ARSession, didFailWithError error: Error) {
        print("ARSession failed: \(error.localizedDescription)")
    }
}
