//
//  NetworkError.swift
//  NetworkKit
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

public enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(code: Int, body: Data?)
    case decoding(Error)
    case transport(Error)
}
