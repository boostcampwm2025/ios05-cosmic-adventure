import ARKit
import SpriteKit
import SwiftUI

public struct GameView: View {
    @StateObject private var inputManager: InputManager<ARKitFaceInputSource, FaceInputMapper>
    @StateObject private var gameplayManager = GameplayManager()

    @State private var gameScene: GameScene?

    public init() {
        // 제네릭 InputManager 초기화 (Convenience init 사용)
        _inputManager = StateObject(wrappedValue: InputManager())
    }

    public var body: some View {
        ZStack {
            if let scene = gameScene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(Color.clear) // 투명 배경
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .overlay(alignment: .topTrailing) {
            ARCameraPreview(session: inputManager.arSession)
                .frame(width: 120, height: 160)
                .cornerRadius(12)
                .padding()
                .shadow(radius: 4)
        }
        .onAppear {
            setupGame()
        }
        .onDisappear {
            stopGame()
        }
    }

    // MARK: - Private Methods

    private func setupGame() {
        inputManager.start()

        gameplayManager.bind(inputProvider: inputManager)

        let scene = GameScene(size: UIScreen.main.bounds.size, gameplayManager: gameplayManager)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear // 카메라 보이게 투명
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
