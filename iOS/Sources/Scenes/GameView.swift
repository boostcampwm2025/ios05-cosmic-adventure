import ARKit
import SpriteKit
import SwiftUI

public struct GameView: View {
    @StateObject private var inputManager: InputManager<ARKitFaceInputSource, FaceInputMapper>
    @StateObject private var gameplayManager = GameplayManager()

    @State private var gameScene: GameScene?
    @State private var currentMapType: MapType = .flat  // 기본값: 평면 맵

    public init() {
        _inputManager = StateObject(wrappedValue: InputManager())
    }

    public var body: some View {
        ZStack {
            if let scene = gameScene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(Color.clear)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        // 맵 전환 버튼
        .overlay(alignment: .topLeading) {
            Button(action: toggleMap) {
                Text(currentMapType == .flat ? "🗺 Flat" : "🗼 Tower")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        // AR 카메라 프리뷰
//        .overlay(alignment: .topTrailing) {
//            ARCameraPreview(session: inputManager.arSession)
//                .frame(width: 120, height: 160)
//                .cornerRadius(12)
//                .padding()
//                .shadow(radius: 4)
//        }
        .onAppear {
            setupGame()
        }
        .onDisappear {
            stopGame()
        }
    }

    // MARK: - Private Methods
    
    private func toggleMap() {
        currentMapType = (currentMapType == .flat) ? .tower : .flat
        setupGame()
    }

    private func setupGame() {
        inputManager.start()
        gameplayManager.bind(inputProvider: inputManager)

        let scene = GameScene(
            size: UIScreen.main.bounds.size,
            gameplayManager: gameplayManager,
            mapType: currentMapType
        )
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        gameScene = scene
    }

    private func stopGame() {
        inputManager.stop()
    }
}

// MARK: - AR Camera Preview Helper

struct ARCameraPreview: UIViewRepresentable {
    let session: ARSession

    func makeUIView(context _: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session = session
        view.automaticallyUpdatesLighting = true
        return view
    }

    func updateUIView(_: ARSCNView, context _: Context) {}
}
