//
//  NetworkFrameworkGameNetworking.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import Network

final class NetworkFrameworkGameNetworking {
    private(set) var state: NetworkingState = .idle
    private let serviceType = "cosmic-adventure"
    
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
            startListener()
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
    
    private func startListener() {
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        
        do {
            let listener = try NWListener(using: params)
            listener.service = .init(
                name: nil,
                type: serviceType
            )
            
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            
            listener.start(queue: .main)
            self.listener = listener
            
        } catch {
            print("Listener start failed:", error)
        }
    }
    
    private func accept(_ connection: NWConnection) {
        self.connection?.cancel()
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        connection.start(queue: .main)
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            startReceiveLoop()
            
        case .failed, .cancelled:
            transition(to: .idle)
            
        default:
            break
        }
    }
    
    private func startReceiveLoop() {
        guard let connection else { return }
        
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 64_000
        ) { [weak self] data, _, _, _ in
            if let data {
                // TODO: 데이터 처리 로직 구현
            }
            self?.startReceiveLoop()
        }
    }
}
