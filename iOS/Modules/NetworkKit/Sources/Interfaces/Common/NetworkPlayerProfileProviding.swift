//
//  NetworkPlayerProfileProviding.swift
//  NetworkKit
//
//  Created by 영빈 on 2/4/26.
//

import Foundation

/// 네트워크 계층에서 플레이어 프로필 정보를 제공하는 프로토콜.
public protocol NetworkPlayerProfileProviding {
    var nickname: String { get }
    var characterRawValue: String { get }
}
