//
//  ARFaceTrackingService.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import ARKit
import Combine

final class ARFaceTrackingService: NSObject, FaceTrackingService {
    
    private let session: ARSession
    private let strategy: FaceInputStrategy
    private let subject = PassthroughSubject<GameEvent, Never>()
    
    var events: AnyPublisher<GameEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(strategy: FaceInputStrategy) {
        self.session = ARSession()
        self.strategy = strategy
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
    
    func previewSession() -> ARSession {
        session
    }
}

extension ARFaceTrackingService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARFaceAnchor }) {
            let events = strategy.interpret(anchor: anchor)
            events.forEach { subject.send($0) }
        }
    }
}
