//
//  AppLifecycleStore.swift
//  App
//
//  Created by 영빈 on 1/22/26.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class AppLifecycleStore {
    private(set) var scenePhase: ScenePhase = .inactive
    
    func update(_ phase: ScenePhase) {
        scenePhase = phase
    }
}
