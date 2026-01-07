//
//  SessionProvider.swift
//  NetworkKit
//
//  Created by 강윤서 on 1/6/26.
//

import Foundation
import Observation
import os

@Observable
public final class NetworkSessionManager: ConnectionSessionProvider {
    
    // MARK: - Properties

    private var host: HostManaging
    private var client: ClientManaging

    private var myNickname: String?
    public var nearbyPlayer: [Peer] = []

    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "NetworkSessionManager")

    // MARK: - Callbacks

    public var onLocalNetworkPermissionGranted: (() -> Void)?
    public var onLocalNetworkPermissionDenied: ((Error) -> Void)?

    // MARK: - Initialization

    public init(host: HostManaging, client: ClientManaging) {
        self.host = host
        self.client = client

        setupCallbacks()
    }

    public convenience init() {
        self.init(
            host: HostManager(),
            client: ClientManager()
        )
    }

    // MARK: - Public Methods

    public func activate(nickname: String) {
        logger.info("호스팅, 탐색 시작")
        logger.info("내 닉네임: \(nickname)")
        
        myNickname = nickname
        
        host.startHosting(nickName: nickname, status: .available)
        client.startBrowsing()
    }

    public func deactive() {
        logger.info("호스팅, 탐색 중단")

        host.stopHosting()
        client.stopBrowsing()

        nearbyPlayer.removeAll()
        myNickname = nil
    }

    // MARK: - Private Methods

    private func setupCallbacks() {
        host.onPermissionGranted = { [weak self] in
            self?.logger.info("호스트 권한 확인")
            self?.onLocalNetworkPermissionGranted?()
        }

        host.onPermissionDeniedOrFailed = { [weak self] error in
            self?.logger.error("호스트 권한 없음: \(error.localizedDescription)")
            self?.onLocalNetworkPermissionDenied?(error)
        }

        client.onPermissionGranted = { [weak self] in
            self?.logger.info("클라이언트 권한 확인")
            self?.onLocalNetworkPermissionGranted?()
        }

        client.onPermissionDeniedOrFailed = { [weak self] error in
            self?.logger.error("클라이언트 권한 없음: \(error.localizedDescription)")
            self?.onLocalNetworkPermissionDenied?(error)
        }

        client.onPeersUpdated = { [weak self] peers in
            guard let self else { return }
            let filteredPeers = peers.filter { $0.name != self.myNickname }

            // UI에 표시될 순서대로 정렬(연결 가능한 순서대로 처리)
            // 추후 변경 가능성 존재
            self.nearbyPlayer = filteredPeers.sorted { peer1, peer2 in
                if peer1.status == .available && peer2.status == .busy {
                    return true
                } else if peer1.status == .busy && peer2.status == .available {
                    return false
                } else {
                    return peer1.name < peer2.name
                }
            }
        }
    }
}
