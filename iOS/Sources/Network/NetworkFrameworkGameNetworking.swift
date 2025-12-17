//
//  NetworkFrameworkGameNetworking.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import Network

final class NetworkFrameworkGameNetworking {
    private(set) var state: NetworkingState = .idle

    // MARK: - Components
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    // MARK: - Public API
     func start() {
         transition(to: .idle)
     }

     func connect(to peer: Peer) {
         transition(to: .connecting(peer))
     }

     func disconnect() {
         transition(to: .idle)
     }
}

private extension NetworkFrameworkGameNetworking {

    func transition(to newState: NetworkingState) {
        cleanup()
        state = newState

        switch newState {
        case .idle:

        case .connecting(let peer):

        case .connected:
            
        }
    }

    func cleanup() {
        listener?.cancel()
        browser?.cancel()
        connection?.cancel()
        listener = nil
        browser = nil
        connection = nil
    }
}
