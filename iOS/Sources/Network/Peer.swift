//
//  Peer.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import Foundation
import Network

struct Peer: Identifiable {
    let id: UUID
    let name: String
    let endpoint: NWEndpoint
}
