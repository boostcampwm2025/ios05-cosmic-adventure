//
//  HTTPClient.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public enum HTTPError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
}

public final class HTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = .init()
    ) {
        self.session = session
        self.decoder = decoder
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(http.statusCode) else {
                throw NetworkError.httpStatus(code: http.statusCode, body: data)
            }

            return (data, http)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transport(error)
        }
    }

    public func request<T: DecodableResponse>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, _) = try await send(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
