//
//  P2PManager.swift
//  iOS
//
//  Created by soyoung on 12/17/25.
//

import Network
import Observation
import UIKit

// 발견된 유저 모델
struct Peer: Identifiable, Hashable {
    var id: String { endpoint.debugDescription }
    let endpoint: NWEndpoint

    var name: String {
        if case let .service(name, _, _, _) = endpoint {
            return name
        }
        return "Unknown User"
    }
}

// 데이터 종류를 구분하기 위한 헤더 (나중에 확장 가능)
enum PacketType: UInt8 {
    case command = 0 // 점프 같은 텍스트 명령어
    case image = 1   // 영상 프레임 데이터
}

@Observable
class P2PManager {
    // 설정
    private let serviceType = "_cosmicgame._tcp"

    // 내 이름 (랜덤 ID 부여)
    var myName: String = {
        let deviceName = UIDevice.current.name
        let randomId = Int.random(in: 10...99)
        return "\(deviceName)-\(randomId)"
    }()

    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?

    var availablePeers: [Peer] = []
    var isConnected: Bool = false

    // 받은 데이터 (텍스트)
    var receivedAction: String = ""
    // 받은 데이터 (이미지) - 나중에 쓸 것!
    var receivedImageData: Data? = nil

    init() {
        print("P2PManager 초기화: 내 이름 [\(myName)]")
        startAdvertising()
        startBrowsing()
    }

    // MARK: - 1. 이름 변경 및 재시작
    func changeMyName(to newName: String) {
        print("이름을 [\(newName)]으로 변경 중...")
        listener?.cancel()
        self.myName = newName
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startAdvertising()
        }
    }

    // MARK: - 2. 대기실 (Advertising & Browsing)
    private func startAdvertising() {
        do {
            let parameters = NWParameters.tcp
            // 중요: 로컬 네트워크(블루투스/AWDL) 자동 전환 활성화
            parameters.includePeerToPeer = true

            listener = try NWListener(using: parameters)
            listener?.service = NWListener.Service(name: myName, type: serviceType)

            listener?.newConnectionHandler = { [weak self] newConnection in
                print("[Listener] 누군가 나에게 연결 시도!")
                self?.acceptConnection(newConnection)
            }
            listener?.start(queue: .main)
            print("[Listener] 방송 시작")
        } catch {
            print("[Listener] 에러: \(error)")
        }
    }

    private func startBrowsing() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true // 중요!
        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: nil)

        browser = NWBrowser(for: descriptor, using: parameters)
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            let peers = results.map { Peer(endpoint: $0.endpoint) }
            DispatchQueue.main.async {
                self?.availablePeers = peers
            }
        }
        browser?.start(queue: .main)
    }

    // MARK: - 3. 연결 설정
    func connectTo(peer: Peer) {
        print("[Connect] 연결 요청: \(peer.name)")
        connection?.cancel()
        let newConnection = NWConnection(to: peer.endpoint, using: .tcp)
        self.connection = newConnection
        setupConnection(newConnection)
        newConnection.start(queue: .main)
    }

    private func acceptConnection(_ newConnection: NWConnection) {
        print("[Accept] 연결 수락")
        connection?.cancel()
        self.connection = newConnection
        setupConnection(newConnection)
        newConnection.start(queue: .main)
    }

    private func setupConnection(_ conn: NWConnection) {
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("연결 성공! (State: Ready)")
                DispatchQueue.main.async {
                    self?.isConnected = true
                    self?.stopDiscovery()
                }
                // 연결되면 데이터 수신 시작 (프로토콜 변경됨!)
                self?.receiveHeader(from: conn)

            case .failed(let error):
                print("연결 실패: \(error)")
                DispatchQueue.main.async { self?.isConnected = false }
            case .cancelled:
                DispatchQueue.main.async { self?.isConnected = false }
            default: break
            }
        }
    }

    private func stopDiscovery() {
        browser?.cancel()
        listener?.cancel()
    }

    // MARK: - 4. 데이터 수신 (프로토콜 업그레이드됨 ✨)

    // 단계 1: 헤더(데이터 크기 4바이트 + 타입 1바이트 = 총 5바이트) 읽기
    private func receiveHeader(from conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 5, maximumLength: 5) { [weak self] data, _, _, error in
            if let error = error {
                print("수신 에러: \(error)")
                self?.isConnected = false
                return
            }

            guard let data = data, data.count == 5 else {
                // 연결이 끊기거나 데이터가 없으면 종료
                return
            }

            // 1. 데이터 크기 추출 (앞 4바이트)
            let bodyLength = data.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }

            // 2. 데이터 타입 추출 (뒤 1바이트)
            let typeByte = data[4]
            let packetType = PacketType(rawValue: typeByte) ?? .command

            // 단계 2: 실제 데이터 본문 읽기
            self?.receiveBody(from: conn, length: Int(bodyLength), type: packetType)
        }
    }

    // 단계 2: 본문(Body) 읽기
    private func receiveBody(from conn: NWConnection, length: Int, type: PacketType) {
        conn.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, _, error in
            if let data = data, data.count == length {

                // 받은 데이터 처리
                switch type {
                case .command:
                    // 텍스트 명령 (jump 등)
                    if let message = String(data: data, encoding: .utf8) {
                        print("[Command] 수신: \(message)")
                        DispatchQueue.main.async {
                            self?.receivedAction = message
                        }
                    }
                case .image:
                    // 이미지 데이터 (나중에 구현)
//                    print("[Image] 이미지 수신 완료 (\(data.count) bytes)")
                    DispatchQueue.main.async {
                        self?.receivedImageData = data
                    }
                }
            }

            // 단계 3: 다시 다음 패킷의 헤더 읽기 대기 (재귀 호출)
            self?.receiveHeader(from: conn)
        }
    }

    // MARK: - 5. 데이터 전송 (프로토콜 업그레이드)

    // 텍스트 전송용 (기존 코드 호환)
    func send(action: String) {
        guard let data = action.data(using: .utf8) else { return }
        sendData(data, type: .command)
    }

    // 이미지 전송용 (새로 추가됨!)
    func sendImage(data: Data) {
        sendData(data, type: .image)
    }

    // 실제 전송 내부 함수 (헤더 붙이기)
    private func sendData(_ body: Data, type: PacketType) {
        var length = UInt32(body.count)

        // 1. 헤더 만들기: [길이(4byte)] + [타입(1byte)]
        var header = Data(bytes: &length, count: 4)
        header.append(type.rawValue)

        // 2. 합치기: [헤더] + [바디]
        let finalPacket = header + body

        connection?.send(content: finalPacket, completion: .contentProcessed({ error in
            if let error = error {
                print("전송 실패: \(error)")
            }
        }))
    }
}
