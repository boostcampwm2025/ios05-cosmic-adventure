//
//  LobbyViewModel+P2P.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import NetworkKit

// MARK: - P2P

extension LobbyViewModel {

    func setupSessionManager() {
        guard sessionManager != nil else { return }
        
        activeAlert = .none
        sessionManager?.onPermissionResult = { [weak self] result in
            guard case .failure(let error) = result else { return }
            
            Task { @MainActor in 
                self?.activeAlert = (error == .denied) ? .permissionDenied : .unknownNetworkError
            }
        }

        sessionManager?.onReceiveInvitationPacket = { [weak self] type, data in
            self?.handleInvitationPacket(type: type, data: data)
        }
    }

    private func handleInvitationPacket(type: NetworkPacketType, data: Data) {
        // 보낸 사람(Peer) 찾기
        guard let packet = try? decoder.decode(InvitationPacket.self, from: data),
              let peer = peers.first(where: { $0.displayName == packet.senderIdentifier }) else {
            return }

        Task { @MainActor in
            switch type {
            case .invite:
                switch matchStatus {
                case .idle:
                    matchStatus.receiveInvite(from: peer)

                case .gameReady, .gameStart:
                    declineInGame(peer: peer)

                default:
                    break
                }

            case .accept:
                if case .sendingRequest = matchStatus {
                    matchStatus.setGameReady(with: peer)
                }

            case .cancelInvite:
                if case .receivedInvite = matchStatus {
                    resetToIdle()
                }

            case .decline:
                if case .sendingRequest = matchStatus {
                    matchStatus.requestDeclined(by: peer)
                }
            }
        }
    }

    private func resetToIdle() {
        matchStatus.reset()
        selectedPeerID = nil
    }
}
