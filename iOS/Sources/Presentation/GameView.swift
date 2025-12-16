import SwiftUI
import SpriteKit
import Foundation

struct GameView: View {
    @StateObject var faceTrackingManager = FaceTrackingManager()
    @StateObject var gestureController = FaceGestureController()

    @State private var lastLoggedMouthPucker: Float = 0
    @State private var lastLoggedHeadRoll: Float = 0

    // GameScene을 State로 관리하여 재생성 방지
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    CameraPIPView(session: faceTrackingManager.arSession)
                        .frame(width: 120, height: 160)
                        .cornerRadius(12)
                        .padding()
                        .shadow(radius: 4)
                }
                Spacer()
            }

            // 디버그: pucker + headRoll만 표시
            VStack(spacing: 8) {
                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    let rollDegrees = gestureController.headRoll * 180 / Float.pi

                    Text(String(format: "mouthPucker: %.2f", gestureController.mouthPucker))
                    Text(String(format: "headRoll: %.2f rad (%.1f°)", gestureController.headRoll, rollDegrees))
                }
                .foregroundColor(.red)
                .font(.headline)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
            }
            .padding(.bottom, 50)
        }
        .onAppear { faceTrackingManager.startTracking() }
        .onDisappear { faceTrackingManager.stopTracking() }
        .onChange(of: faceTrackingManager.updateCounter) { _, _ in
            gestureController.update(blendShapes: faceTrackingManager.blendShapes, headTransform: faceTrackingManager.headTransform)

            // 로그: mouthPucker + headRoll 같이
            if abs(gestureController.mouthPucker - lastLoggedMouthPucker) > 0.05 || abs(gestureController.headRoll - lastLoggedHeadRoll) > 0.05 {
                print("[FaceTracking] mouthPucker:", gestureController.mouthPucker, "headRoll:", gestureController.headRoll)
                lastLoggedMouthPucker = gestureController.mouthPucker
                lastLoggedHeadRoll = gestureController.headRoll
            }

            // 이동은 지속 적용
            gameScene.handleMove(intensity: CGFloat(gestureController.movementX))

            // 점프는 1회성 이벤트로 적용
            if let intensity = gestureController.consumeJumpIntensity() {
                gameScene.handleJump(intensity: CGFloat(intensity))
            }
        }
    }

}
