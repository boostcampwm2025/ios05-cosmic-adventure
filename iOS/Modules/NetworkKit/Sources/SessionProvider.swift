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
    
    private var hostGranted: Bool? = nil
    private var clientGranted: Bool? = nil
    private var myNickname: String?
    public var nearbyPlayer: [Peer] = []
    
    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "NetworkSessionManager")
    
    // MARK: - Callbacks
    
    public var onLocalNetworkPermissionGranted: (() -> Void)?
    public var onLocalNetworkPermissionDenied: (() -> Void)?
    
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
        
        hostGranted = nil
        clientGranted = nil
    }
    
    // MARK: - Private Methods
    
    private func setupCallbacks() {
        host.onPermissionGranted = { [weak self] in
            self?.hostGranted = true
            self?.checkBothPermission()
        }
        
        host.onPermissionDeniedOrFailed = { [weak self] _ in
            self?.hostGranted = false
            self?.onLocalNetworkPermissionDenied?()
        }
        
        client.onPermissionGranted = { [weak self] in
            self?.clientGranted = true
            self?.checkBothPermission()
        }
        
        client.onPermissionDeniedOrFailed = { [weak self] _ in
            self?.clientGranted = false
            self?.onLocalNetworkPermissionDenied?()
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
    
    private func checkBothPermission() {
        if hostGranted == true && clientGranted == true {
            onLocalNetworkPermissionGranted?()
        }
    }
}
