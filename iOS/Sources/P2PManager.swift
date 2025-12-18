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
    // UUID()를 매번 생성하지 않고, endpoint 자체를 식별자로 사용해야 리스트가 안정됨
    var id: String { endpoint.debugDescription }
    let endpoint: NWEndpoint

    var name: String {
        if case let .service(name, _, _, _) = endpoint {
            return name
        }
        return "Unknown User"
    }
}

@Observable
class P2PManager {
    // 설정
    private let serviceType = "_cosmicgame._tcp"
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
    var receivedAction: String = ""

    init() {
        print("P2PManager 초기화: 내 이름 [\(myName)]")
        startAdvertising()
        startBrowsing()
    }

    // MARK: - 1. 대기실 (Advertising & Browsing)
    private func startAdvertising() {
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters)
            listener?.service = NWListener.Service(name: myName, type: serviceType)

            listener?.newConnectionHandler = { [weak self] newConnection in
                print("[Listener] 누군가 나에게 연결 시도! (Endpoint: \(newConnection.endpoint))")
                self?.acceptConnection(newConnection)
            }

            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready: print("[Listener] 방송 시작 (내 기기 검색 가능)")
                case .failed(let error): print("[Listener] 방송 실패: \(error)")
                case .cancelled: print("[Listener] 방송 중지됨")
                default: break
                }
            }
            listener?.start(queue: .main)
        } catch {
            print("[Listener] 생성 에러: \(error)")
        }
    }

    private func startBrowsing() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: nil)

        browser = NWBrowser(for: descriptor, using: parameters)

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            // 검색 결과가 바뀔 때마다 로그 출력
            print("[Browser] 발견된 기기 수: \(results.count)명")

            let peers = results.map { Peer(endpoint: $0.endpoint) }

            // UI 업데이트는 메인 스레드 보장
            DispatchQueue.main.async {
                self?.availablePeers = peers
            }
        }

        browser?.start(queue: .main)
    }

    // MARK: - 2. 연결 로직 (핵심 디버깅 구간)

    // [CASE A] 내가 버튼을 눌러서 연결 요청
    func connectTo(peer: Peer) {
        print("[Connect] '\(peer.name)'에게 연결 요청 시작...")

        connection?.cancel() // 기존 연결 정리

        let newConnection = NWConnection(to: peer.endpoint, using: .tcp)
        self.connection = newConnection

        setupConnection(newConnection, isInitiator: true)
        newConnection.start(queue: .main)
    }

    // [CASE B] 상대가 나에게 연결해와서 수락
    private func acceptConnection(_ newConnection: NWConnection) {
        print("[Accept] 상대방 연결 수락 중...")

        connection?.cancel()
        self.connection = newConnection

        setupConnection(newConnection, isInitiator: false)
        newConnection.start(queue: .main)
    }

    // 공통 연결 설정
    private func setupConnection(_ conn: NWConnection, isInitiator: Bool) {
        conn.stateUpdateHandler = { [weak self] state in
            let role = isInitiator ? "[발신자]" : "[수신자]"

            switch state {
            case .preparing:
                print("\(role) 연결 준비 중...")
            case .ready:
                print("\(role) 연결 성공! (State: Ready)")

                // 화면 전환 트리거 (반드시 메인 스레드)
                DispatchQueue.main.async {
                    self?.isConnected = true
                    self?.stopDiscovery() // 연결되면 탐색/방송 중지
                    print("[UI] isConnected = true 변경 완료")
                }
                self?.receiveData()

            case .failed(let error):
                print("\(role) 연결 실패: \(error)")
                DispatchQueue.main.async { self?.isConnected = false }

            case .cancelled:
                print("\(role) 연결 취소됨")
                DispatchQueue.main.async { self?.isConnected = false }

            case .waiting(let error):
                print("\(role) 연결 대기 중 (재시도 예정): \(error)")

            @unknown default:
                break
            }
        }
    }

    // MARK: - 3. 데이터 송수신
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                // 줄바꿈 기준으로 쪼개서 처리 (jumpjump 문제 해결)
                let commands = message.split(separator: "\n")
                for command in commands {
                    let cleanAction = String(command)
                    print("[Data] 수신: \(cleanAction)")

                    DispatchQueue.main.async {
                        self?.receivedAction = cleanAction
                    }
                }
            }

            if isComplete {
                print("[Connection] 상대방이 연결을 끊음")
                DispatchQueue.main.async { self?.isConnected = false }
            } else if let error = error {
                print("[Connection] 수신 에러: \(error)")
            } else {
                self?.receiveData() // 계속 수신 대기
            }
        }
    }

    func send(action: String) {
        let messageToSend = action + "\n"
        guard let data = messageToSend.data(using: .utf8) else { return }

        connection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("[Send] 전송 실패: \(error)")
            } else {
                // print("[Send] 전송 성공: \(action)") // 너무 시끄러우면 주석 처리
            }
        }))
    }

    private func stopDiscovery() {
        print("[System] 연결 성사로 인해 탐색 및 방송 중지")
        browser?.cancel()
        listener?.cancel()
    }
}
