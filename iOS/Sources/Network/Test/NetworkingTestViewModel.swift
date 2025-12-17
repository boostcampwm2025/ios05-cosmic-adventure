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

    private let networking: NetworkFrameworkGameNetworking
    private var cancellables = Set<AnyCancellable>()

    init(networking: NetworkFrameworkGameNetworking) {
        self.networking = networking

        networking.availablePeers
            .receive(on: DispatchQueue.main)
            .assign(to: &$peers)
    }

    func start() {
        networking.start()
        stateText = "Searching..."
    }

    func connect(to peer: Peer) {
        networking.connect(to: peer)
        stateText = "Connecting to \(peer.name)"
    }
}
