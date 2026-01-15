import Foundation
import Observation

@Observable
public final class WebSocketService: NSObject {

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var isConnected = false

    public private(set) var sessionId: String?
    public private(set) var channelId: String?
    public private(set) var nickname: String?

    public var onMessage: ((WebSocketMessage) -> Void)?
    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    public func connect(to wsURL: String, channelId: String, nickname: String) {
        guard !isConnected else { return }

        self.channelId = channelId
        self.nickname = nickname

        let urlString = "\(wsURL)/ws?channelId=\(channelId)&nickname=\(nickname)"
        guard let url = URL(string: urlString) else { return }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        isConnected = true
        receiveMessage()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        sessionId = nil
        channelId = nil
        nickname = nil
    }

    public func send(_ message: WebSocketMessage) {
        guard isConnected else { return }

        do {
            let data = try encoder.encode(message)
            guard let text = String(data: data, encoding: .utf8) else { return }

            webSocketTask?.send(.string(text)) { [weak self] error in
                if let error {
                    self?.handleError(error)
                }
            }
        } catch {
            handleError(error)
        }
    }

    public func joinChannel() {
        let message = WebSocketMessage(type: .channelJoin, senderId: sessionId ?? "")
        send(message)
    }

    public func leaveChannel() {
        let message = WebSocketMessage(type: .channelLeave, senderId: sessionId ?? "")
        send(message)
    }

    public func sendInvite(to targetId: String) {
        let message = WebSocketMessage(type: .invite, senderId: sessionId ?? "", payload: targetId)
        send(message)
    }

    public func sendPing() {
        let message = WebSocketMessage(type: .ping, senderId: sessionId ?? "")
        send(message)
    }

    public func sendPong() {
        let message = WebSocketMessage(type: .pong, senderId: sessionId ?? "")
        send(message)
    }

    public func acceptInvite(from senderId: String) {
        let message = WebSocketMessage(type: .inviteAccept, senderId: sessionId ?? "", payload: senderId)
        send(message)
    }

    public func declineInvite(from senderId: String) {
        let message = WebSocketMessage(type: .inviteDecline, senderId: sessionId ?? "", payload: senderId)
        send(message)
    }

    public func cancelInvite(to targetId: String) {
        let message = WebSocketMessage(type: .inviteCancel, senderId: sessionId ?? "", payload: targetId)
        send(message)
    }

    public func sendInput(_ inputData: String, to targetId: String) {
        let message = WebSocketMessage(type: .input, senderId: sessionId ?? "", payload: inputData)
        send(message)
    }

    public func sendReadyStatus(to targetId: String) {
        let message = WebSocketMessage(type: .gameReady, senderId: sessionId ?? "", payload: targetId)
        send(message)
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage()
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let webSocketMessage = try? decoder.decode(WebSocketMessage.self, from: data) else {
                return
            }

            if webSocketMessage.messageType == .channelPlayerList, sessionId == nil {
                extractSessionId(from: webSocketMessage)
            }

            DispatchQueue.main.async { [weak self] in
                self?.onMessage?(webSocketMessage)
            }

        case .data:
            break

        @unknown default:
            break
        }
    }

    private func extractSessionId(from message: WebSocketMessage) {
        guard let payload = message.payload,
              let nickname = self.nickname else { return }

        let players = payload.split(separator: "|")
        for player in players {
            let parts = player.split(separator: ":")
            if parts.count >= 2, String(parts[1]) == nickname {
                sessionId = String(parts[0])
                break
            }
        }
    }

    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.onDisconnect?(error)
        }
        isConnected = false
    }
}

extension WebSocketService: URLSessionWebSocketDelegate {
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.onConnect?()
        }
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.onDisconnect?(nil)
        }
        isConnected = false
    }
}
