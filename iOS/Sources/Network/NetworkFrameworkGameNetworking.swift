//
//  NetworkFrameworkGameNetworking.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/17/25.
//

import Combine
import Foundation
import Network

final class NetworkFrameworkGameNetworking {
    let serviceType: String
    private(set) var state: NetworkingState = .idle
    private var peers: [Peer] = []
    
    // MARK: - Components
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    private let peersSubject = CurrentValueSubject<[Peer], Never>([])

    var availablePeers: AnyPublisher<[Peer], Never> {
        peersSubject.eraseToAnyPublisher()
    }
    
    init(serviceType: String) {
        self.serviceType = serviceType
    }
    
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
            startBrowser()
            
        case .connecting(let peer):
            startConnection(to: peer)

        case .connected:
            break
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

// MARK: Listener
private extension NetworkFrameworkGameNetworking {
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
}

// MARK: Browser
private extension NetworkFrameworkGameNetworking {
    private func startBrowser() {
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        
        let browser = NWBrowser(
            for: .bonjour(type: serviceType, domain: nil),
            using: params
        )
        
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleBrowseResults(results)
        }
        
        browser.start(queue: .main)
        self.browser = browser
    }
    
    private func handleBrowseResults(
        _ results: Set<NWBrowser.Result>
    ) {
        let newPeers: [Peer] = results.compactMap { result in
            if case let .service(name, _, _, _) = result.endpoint {
                return Peer(
                    id: UUID(),
                    name: name,
                    endpoint: result.endpoint
                )
            } else {
                return nil
            }
        }

        peersSubject.send(newPeers)
    }
}

// MARK: Connection
private extension NetworkFrameworkGameNetworking {
    private func startConnection(to peer: Peer) {
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        
        let connection = NWConnection(
            to: peer.endpoint,
            using: params
        )
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        connection.start(queue: .main)
        self.connection = connection
    }
}
