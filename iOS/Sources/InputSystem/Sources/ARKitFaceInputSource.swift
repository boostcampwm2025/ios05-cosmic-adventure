import ARKit
import Combine

/// ARKit 기반 얼굴 입력 소스
final class ARKitFaceInputSource: NSObject, ObservableObject, InputSourceProtocol, ARSessionProviding {
    typealias Raw = FaceRawInput

    // MARK: - Raw Output

    /// 머리 기울기 (radians). 왼쪽 기울임(+), 오른쪽 기울임(-)
    @Published private(set) var roll: Double = 0

    /// 입 오므리기 (0.0 ~ 1.0)
    @Published private(set) var mouthPucker: Double = 0

    // MARK: - InputSource

    var rawPublisher: AnyPublisher<FaceRawInput, Never> {
        Publishers.CombineLatest($roll, $mouthPucker)
            .map { FaceRawInput(roll: $0, mouthPucker: $1) }
            .eraseToAnyPublisher()
    }

    // MARK: - ARSession

    private let session = ARSession()

    var arSession: ARSession { session }
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("[ARKitFaceInputSource] Face tracking is not supported on this device")
            return
        }

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }
    
    // MARK: - Helpers
    
    private func extractRoll(from transform: simd_float4x4) -> Double {
        Double(atan2(transform.columns.0.y, transform.columns.0.x))
    }
}

// MARK: - ARSessionDelegate

extension ARKitFaceInputSource: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        let newRoll = extractRoll(from: faceAnchor.transform)
        let newPucker = Double(faceAnchor.blendShapes[.mouthPucker]?.floatValue ?? 0)
        
        DispatchQueue.main.async { [weak self] in
            self?.roll = newRoll
            self?.mouthPucker = newPucker
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("[ARKitFaceInputSource] ARSession failed: \(error.localizedDescription)")
    }
}
