import Foundation

struct WSMessage: Codable {
    let type: String
    let senderId: String
    let payload: String?
    let timestamp: Date?

    init(type: String, senderId: String, payload: String? = nil) {
        self.type = type
        self.senderId = senderId
        self.payload = payload
        self.timestamp = Date()
    }

    static func decode(from text: String) -> WSMessage? {
        guard let data = text.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WSMessage.self, from: data)
    }

    func encode() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
