//
//  FaceTrackingService.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import Combine

protocol FaceTrackingService {
    var events: AnyPublisher<GameEvent, Never> { get }
    
    func start()
    func stop()
}
