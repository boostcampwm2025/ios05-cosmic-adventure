//
//  HTTPClientProtocol.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public protocol HTTPClientProtocol: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
    func request<T: DecodableResponse>(_ request: URLRequest, as type: T.Type) async throws -> T
}

public extension HTTPClientProtocol {
    func request<T: DecodableResponse>(_ request: URLRequest) async throws -> T {
        try await self.request(request, as: T.self)
    }
}
