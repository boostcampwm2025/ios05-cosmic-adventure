//
//  Channel.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import Foundation

enum ChannelStatus: String, Codable, Sendable {
    case available
    case full
}

struct Channel: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let currentPlayers: Int
    let maxPlayers: Int
    let status: ChannelStatus
    
    var isFull: Bool {
        status == .full
    }
    
    var playerCountText: String {
        "\(currentPlayers)/\(maxPlayers)"
    }
}
