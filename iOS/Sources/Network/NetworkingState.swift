//
//  Untitled.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

enum NetworkingState {
    case idle
    case connecting(Peer)
    case connected(peer: Peer, isAuthority: Bool)
}
