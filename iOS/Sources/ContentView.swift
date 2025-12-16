import SwiftUI
import SpriteKit

struct ContentView: View {
    // 1. AR 데이터 매니저
    @StateObject var faceManager = FaceTrackingManager()

    // 2. 게임 씬 생성
    @State var gameScene: CosmicGameScene = {
        let scene = CosmicGameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        return scene
    }()

    var body: some View {
        ZStack {
            // 레이어 1: AR 세션
            ARViewContainer(session: faceManager.session)
                .ignoresSafeArea()

            // 레이어 2: 게임 화면 (SpriteView)
            SpriteView(scene: gameScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .background(Color.clear)

            // 레이어 3: 디버그 정보
            VStack {
                HStack {
                    Text("우~: \(String(format: "%.2f", faceManager.mouthPuckerValue))")
                    Text("볼빵빵: \(String(format: "%.2f", faceManager.cheekPuffValue))")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                Spacer()
            }
            .padding(.top, 50)
        }
        // 데이터가 변할 때마다 게임 씬에 알려줌
        .onChange(of: faceManager.cheekPuffValue) { _ in
            updateGameInput()
        }
        .onChange(of: faceManager.mouthPuckerValue) { _ in
            updateGameInput()
        }
        .onChange(of: faceManager.headRoll) { _ in
            updateGameInput()
        }
    }

    // 입력을 게임 씬으로 전달하는 헬퍼 함수
    private func updateGameInput() {
        gameScene.updateInput(
            pucker: faceManager.mouthPuckerValue,
            puff: faceManager.cheekPuffValue,
            jawOpen: faceManager.jawOpenValue,
            roll: faceManager.headRoll
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
