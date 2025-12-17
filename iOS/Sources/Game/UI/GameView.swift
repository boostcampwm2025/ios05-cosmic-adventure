//
//  GameView.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var coordinator = GameCoordinator()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpriteView(scene: coordinator.scene)
                .ignoresSafeArea()
            
            if let service = coordinator.faceTrackingService as? ARFaceTrackingService {
                FacePreviewView(session: service.previewSession())
                    .frame(
                        width: 150,
                        height: 220
                    )
                    .background(.black)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding()
            }
        }
        .onAppear {
            coordinator.start()
        }
        .onDisappear {
            coordinator.stop()
        }
    }
}

#Preview {
    GameView()
}
