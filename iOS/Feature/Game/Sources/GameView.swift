//
//  GameView.swift
//  Game
//
//  Created by 강윤서 on 12/17/25.
//

import SwiftUI
import SpriteKit
import FaceKit
import Engine

public struct GameView: View {
    // 얼굴 인식 매니저
    @StateObject private var faceTracking = FaceTracker()
    @State private var gameScene: GameScene?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if let scene = gameScene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            VStack {
                #warning("TODO: - 디버깅용 뷰로 추후 제거 필요")
                HStack {
                    Text("Face Tracking: \(faceTracking.isTracking ? "ON" : "OFF")")
                    Text("Gesture: \(gestureText)")
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)

                Spacer()

                Button(faceTracking.isTracking ? "Stop Tracking" : "Start Tracking") {
                    if faceTracking.isTracking {
                        faceTracking.stopTracking()
                    } else {
                        faceTracking.startTracking()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            if gameScene == nil {
                createScene()
            }
        }
        // 제스처 변경 감지
        .onChange(of: faceTracking.currentGesture) { _, newGesture in
            handleGesture(newGesture)
        }
    }

    private func createScene() {
        let engine = GameScene()
        engine.size = CGSize(width: UIScreen.main.bounds.width,
                            height: UIScreen.main.bounds.height)
        engine.scaleMode = .aspectFill

        gameScene = engine
    }
    
    // 제스처를 게임 액션으로 변환
    private func handleGesture(_ gesture: FaceGestureType) {
        guard let scene = gameScene else { return }
        
        switch gesture {
        case .jump:
            scene.jump(isSuper: false)
            
        case .superJump:
            scene.jump(isSuper: true)
            
        case .move(.left):
            scene.move(direction: -1)
            
        case .move(.right):
            scene.move(direction: 1)
            
        case .none:
            scene.move(direction: 0)
        }
    }
    
    private var gestureText: String {
        switch faceTracking.currentGesture {
        case .jump: return "입 오므리기"
        case .superJump: return "볼 부풀리기"
        case .move(.left): return "왼쪽 이동"
        case .move(.right): return "오른쪽 이동"
        case .none: return "움직이지 않음"
        }
    }
}
