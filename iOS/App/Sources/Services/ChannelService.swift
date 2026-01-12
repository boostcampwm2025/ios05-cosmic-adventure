//
//  ChannelService.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import NetworkKit

protocol ChannelServiceProtocol: Sendable {
    func fetchChannels() async throws -> [Channel]
}

final class ChannelService: ChannelServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let baseURL: String
    
    init(httpClient: HTTPClientProtocol, baseURL: String) {
        self.httpClient = httpClient
        self.baseURL = baseURL
    }
    
    func fetchChannels() async throws -> [Channel] {
        guard let url = URL(string: "\(baseURL)/api/v1/channels") else {
            throw ChannelServiceError.invalidURL
        }
        let request = URLRequest(url: url)
        return try await httpClient.request(request, as: [Channel].self)
    }
}

enum ChannelServiceError: Error {
    case invalidURL
    case networkError(Error)
}
