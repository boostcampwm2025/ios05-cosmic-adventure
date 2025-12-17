//
//  FaceTracker.swift
//  FaceKit
//
//  Created by 강윤서 on 12/17/25.
//

import ARKit
import Combine
import OSLog

import Core

final public class FaceTracker: NSObject, ObservableObject {
    
    private let arSession = ARSession()
    private let configuration = ARFaceTrackingConfiguration()
    private let logger = Logger()
    
    @Published public private(set) var currentGesture: FaceGestureType = .none          /// 인식된 제스처
    @Published public private(set) var isTracking: Bool = false                          /// 추적 상태
    
    public override init() {
        super.init()
        arSession.delegate = self
        configuration.isLightEstimationEnabled = false
    }
    
    deinit {
        arSession.pause()
        logger.debug("FaceTracker deinit")
    }
    
    /// 얼굴 추적 시작
    public func startTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            logger.error("🚨 해당 기기에서는 얼굴 추적 기능이 지원되지 않습니다.")
            return
        }
        
        arSession.run(configuration)
        isTracking = true
        logger.debug("✅ 얼굴 추적 시작")
    }
    
    
    /// 얼굴 추적 종료
    public func stopTracking() {
        arSession.pause()
        isTracking = false
        currentGesture = .none
        logger.debug("✅ 얼굴 추적 중단")
    }
}

extension FaceTracker: ARSessionDelegate {
    
    /// faceAnchor를 사용해서 어떤 동작인지 판단 후 결과값을 전달
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        
        let gesture = detectGesture(from: faceAnchor)
        
        // 얼굴 이미지 전달
        if gesture.type != currentGesture {
            DispatchQueue.main.async {
                self.currentGesture = gesture.type
            }
        }
    }
    
    private func detectGesture(from faceAnchor: ARFaceAnchor)
    -> (type: FaceGestureType, intensity: Float) {
        
        // 1. BlendShapes 추출
        let blendShapes = faceAnchor.blendShapes
        let mouthPucker = blendShapes[.mouthPucker]?.floatValue ?? 0
        let cheekPuff = blendShapes[.cheekPuff]?.floatValue ?? 0
        
        // 2. Head Transform (고개 기울임)
        let transform = faceAnchor.transform
        let roll = atan2(transform.columns.1.x, transform.columns.1.y)
        let rollDegree = roll * 180 / .pi            // 좌우 기울임 정도
        
        // 3. 제스처 판단
        let gesture = calculateGesture(
            mouthPucker: mouthPucker,
            cheekPuff: cheekPuff,
            roll: rollDegree
        )
        
        return gesture
    }
    
    
    /// - Parameters:
    ///   - mouthPucker: 입 오므리기 정도
    ///   - cheekPuff: 볼 부풀리기 정도
    ///   - roll: 고개 움직임 정도
    /// - Returns: 동작 타입과 움직임 정도 반환
    private func calculateGesture(mouthPucker: Float,
                                  cheekPuff: Float,
                                  roll: Float) -> (type: FaceGestureType, intensity: Float) {
        if cheekPuff > GameConstant.superJumpThreshold {
            return (.superJump, cheekPuff)
        }
        
        if mouthPucker > GameConstant.jumpThreshold {
            return (.jump, mouthPucker)
        }
        
        if roll < -GameConstant.tiltThreshold {
            return (.move(.left), roll)
        }
        
        if roll > GameConstant.tiltThreshold {
            return (.move(.right), roll)
        }
        
        return (.none, 0)
    }
}
