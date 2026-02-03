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

    public func connect(to wsURL: String, channelId: String, nickname: String, characterRawValue: String) {
        guard !isConnected else { return }

        self.channelId = channelId
        self.nickname = nickname

        let urlString = "\(wsURL)/ws?channelId=\(channelId)&nickname=\(nickname)&character=\(characterRawValue)"
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

    public func sendInput<T: Codable>(_ input: T, to targetId: String) {
        guard let inputData = try? encoder.encode(input),
              let inputJSON = String(data: inputData, encoding: .utf8) else { return }

        let payload = ForwardingPayload(to: targetId, data: inputJSON)
        sendForwardingMessage(type: .input, payload: payload)
    }

    public func sendReadyStatus(to targetId: String) {
        let message = WebSocketMessage(type: .gameReady, senderId: sessionId ?? "", payload: targetId)
        send(message)
    }

    public func sendVideo(_ data: Data, to targetId: String) {
        let base64Video = data.base64EncodedString()

        let payload = ForwardingPayload(to: targetId, data: base64Video)
        sendForwardingMessage(type: .videoFrame, payload: payload)
    }

    private func sendForwardingMessage(type: WebSocketMessageType, payload: ForwardingPayload) {
        guard let routedData = try? encoder.encode(payload),
              let payloadString = String(data: routedData, encoding: .utf8) else { return }

        let message = WebSocketMessage(
            type: type,
            senderId: sessionId ?? "",
            payload: payloadString
        )
        send(message)
    }

    public func sendGameEnded(_ dto: NetworkGameEndDTO, to targetId: String) {
        guard let dtoData = try? encoder.encode(dto),
              let dtoString = String(data: dtoData, encoding: .utf8) else { return }
        let routed = ForwardingPayload(to: targetId, data: dtoString)

        guard let routedData = try? encoder.encode(routed),
              let payload = String(data: routedData, encoding: .utf8) else { return }

        send(WebSocketMessage(type: .gameEnded, senderId: sessionId ?? "", payload: payload))
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

            DispatchQueue.main.async { [weak self] in
                self?.onMessage?(webSocketMessage)
            }

        case .data:
            break

        @unknown default:
            break
        }
    }

    public func setSessionId(_ id: String) {
        self.sessionId = id
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
