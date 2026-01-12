import Vapor

final class WSSession: Sendable {
    let id: String
    let ws: WebSocket
    let metadata: [String: String]

    init(id: String = UUID().uuidString, ws: WebSocket, metadata: [String: String] = [:]) {
        self.id = id
        self.ws = ws
        self.metadata = metadata
    }

    var isClosed: Bool {
        ws.isClosed
    }

    func send(_ text: String) async {
        try? await ws.send(text)
    }
}
