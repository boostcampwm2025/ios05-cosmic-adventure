import Vapor

struct WSController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.webSocket("ws") { req, ws in
            let sessionId = UUID().uuidString
            let metadata = extractMetadata(from: req)
            let session = WSSession(id: sessionId, ws: ws, metadata: metadata)

            print("[WS] Client connected: \(sessionId)")

            Task {
                await WSSessionManager.shared.addSession(session)
            }

            ws.onText { ws, text in
                print("[WS] Received: \(text)")
                Task {
                    await WSSessionManager.shared.handleMessage(text, from: sessionId)
                }
            }

            ws.onClose.whenComplete { _ in
                print("[WS] Client disconnected: \(sessionId)")
                Task {
                    await WSSessionManager.shared.removeSession(sessionId)
                }
            }
        }
    }
}

private func extractMetadata(from req: Request) -> [String: String] {
    var metadata: [String: String] = [:]

    if let channelId = req.query[String.self, at: "channelId"] {
        metadata["channelId"] = channelId
    }
    if let nickname = req.query[String.self, at: "nickname"] {
        metadata["nickname"] = nickname
    }
    if let character = req.query[String.self, at: "character"] {
        metadata["character"] = character
    }

    return metadata
}
