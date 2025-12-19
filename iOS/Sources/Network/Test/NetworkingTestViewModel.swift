//
//  Untitled.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/18/25.
//

import Combine
import Foundation

final class NetworkingTestViewModel: ObservableObject {

    @Published var peers: [Peer] = []
    @Published var stateText: String = "Idle"
    @Published var incomingRequest: IncomingConnectionRequest?
    @Published var isIncomingRequestAlertPresented: Bool = false
    @Published var isConnected: Bool = false
    
    private let networking: NetworkFrameworkGameNetworking
    private var cancellables = Set<AnyCancellable>()

    init(networking: NetworkFrameworkGameNetworking) {
        self.networking = networking

        networking.availablePeers
            .receive(on: DispatchQueue.main)
            .assign(to: &$peers)
        
        networking.incomingRequests
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request in
                guard let self else { return }

                // 이미 알럿이 떠있는 동안 추가 요청이 오면, 일단 무시
                guard self.incomingRequest == nil else { return }

                self.incomingRequest = request
                self.isIncomingRequestAlertPresented = true
            }
            .store(in: &cancellables)
        
        networking.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }

                switch state {
                case .idle:
                    self.stateText = "Idle"
                    self.isConnected = false

                case .connecting:
                    break

                case .connected:
                    self.stateText = "Connected"
                    self.isConnected = true
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        networking.start()
        stateText = "Searching..."
    }

    func connect(to peer: Peer) {
        networking.connect(to: peer)
        stateText = "Connecting to \(peer.name)"
    }
    
    func approveIncomingRequest() {
        guard let request = incomingRequest else { return }
        networking.approveIncomingRequest(id: request.id)
        clearIncomingRequest()
    }

    func rejectIncomingRequest() {
        guard let request = incomingRequest else { return }
        networking.rejectIncomingRequest(id: request.id)
        clearIncomingRequest()
    }

    func clearIncomingRequest() {
        incomingRequest = nil
        isIncomingRequestAlertPresented = false
    }
}
