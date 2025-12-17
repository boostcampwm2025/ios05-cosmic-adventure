//
//  GameCoordinator.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import Combine
import UIKit

final class GameCoordinator: ObservableObject {
    let scene: SpriteGameScene
    let faceTrackingService: FaceTrackingService
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let strategy = TiltAndPuckerFaceInputStrategy()
        let service: FaceTrackingService = ARFaceTrackingService(strategy: strategy)
        
        self.faceTrackingService = service
        self.scene = SpriteGameScene(size: .zero)
        
        faceTrackingService.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.scene.handle(event)
            }
            .store(in: &cancellables)
    }
    
    func start() {
        faceTrackingService.start()
    }

    func stop() {
        faceTrackingService.stop()
    }
}
