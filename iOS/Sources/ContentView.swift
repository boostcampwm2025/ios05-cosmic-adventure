import SwiftUI
import SpriteKit

struct ContentView: View {
    // 1. AR 데이터 매니저
    @State var faceManager = FaceTrackingManager()

    // 2. 네트워크 매니저
    @State var p2pManager = P2PManager()
    // 중복 전송 방지용 플래그
    @State private var isJumpSent = false
    // 3. 게임 씬
    @State var gameScene: CosmicGameScene = {
        let scene = CosmicGameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }()

    var body: some View {
        Group {
            if p2pManager.isConnected {
                // [게임 화면] 연결되면 게임 시작
                gameView
            } else {
                // [대기 화면] 주변 유저 목록 표시
                lobbyView
            }
        }
        // 상대방 신호 수신
        .onChange(of: p2pManager.receivedAction) {
            if p2pManager.receivedAction == "jump" {
                print("상대방 점프 신호 받음!")
                // 여기에 상대방 캐릭터 점프 로직 추가 가능
            }
        }
        // 앱 켜지자마자 "이미지 생기면 바로 전송해!"라고 연결
        .onAppear {
            faceManager.onImageCaptured = { imageData in
                // 연결된 상태면 이미지 전송
                if p2pManager.isConnected {
                    p2pManager.sendImage(data: imageData)
                }
            }
        }
    }

    // 대기 화면 (Lobby)
    var lobbyView: some View {
        NavigationView {
            VStack {
                Text("내 기기 이름: \(p2pManager.myName)")
                    .font(.headline)
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.top, 10)

                List(p2pManager.availablePeers) { peer in
                    Button {
                        p2pManager.connectTo(peer: peer) // 터치하면 연결 시도
                    } label: {
                        HStack {
                            Image(systemName: "iphone")
                            Text(peer.name)
                            Spacer()
                            Text("대결하기")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("상대 찾는 중...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProgressView()
                }
            }
        }
    }

    // 게임 화면
    var gameView: some View {
        ZStack {
            // 1. 내 배경 (AR 카메라)
            ARViewContainer(session: faceManager.session)
                .ignoresSafeArea()

            // 2. 게임 씬
            SpriteView(scene: gameScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .background(Color.clear)

            // 3. UI 오버레이
            VStack {
                // 상단 영역
                HStack {
                    // 왼쪽: 내 수치
                    Text("우~: \(String(format: "%.2f", faceManager.mouthPuckerValue))")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)

                    Spacer()

                    // 오른쪽: 상대방 얼굴 화면 (Pip 모드)
                    if let receivedData = p2pManager.receivedImageData,
                       let opponentImage = UIImage(data: receivedData) {
                        Image(uiImage: opponentImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 150) // 작은 화면 크기
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 5)
                    } else {
                        // 영상 수신 전이면 대기 문구
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 100, height: 150)
                            .cornerRadius(12)
                            .overlay(Text("상대방\n대기중").font(.caption).foregroundColor(.white))
                    }
                }
                .padding()

                Spacer()
            }
        }
        // 내 행동 -> 네트워크 전송
        .onChange(of: faceManager.mouthPuckerValue) {
            gameScene.updateInput(
                pucker: faceManager.mouthPuckerValue,
                puff: faceManager.cheekPuffValue,
                jawOpen: faceManager.jawOpenValue,
                roll: faceManager.headRoll
            )

            // "우~" 해서 점프하면 상대에게도 전송
            // 임계값(0.3)을 넘었고, 아직 전송 안 한 상태일 때만 보냄
            if faceManager.mouthPuckerValue > 0.3 {
                if !isJumpSent {
                    p2pManager.send(action: "jump")
                    isJumpSent = true // "보냈음"으로 상태 변경 (잠금)
                    print("점프 신호 1회 전송")
                }
            }
            // 입을 풀어서(0.2 미만) 다시 돌아오면 잠금 해제
            else if faceManager.mouthPuckerValue < 0.2 {
                isJumpSent = false
            }
        }
    }
}
