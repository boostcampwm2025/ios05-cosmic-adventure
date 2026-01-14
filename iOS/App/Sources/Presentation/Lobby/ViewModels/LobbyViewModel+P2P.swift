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
        activeAlert = .none
        networkSessionManager.onPermissionResult = { [weak self] result in
            guard case .failure(let error) = result else { return }
            
            Task { @MainActor in 
                self?.activeAlert = (error == .denied) ? .permissionDenied : .unknownNetworkError
            }
        }
    }

    func setupP2PCallbacks() {
        networkSessionManager.onInviteReceived = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteReceived(from: senderName)
            }
        }

        networkSessionManager.onInviteAccepted = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteAccepted(from: senderName)
            }
        }

        networkSessionManager.onInviteDeclined = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteDeclined(from: senderName)
            }
        }

        networkSessionManager.onInviteCancelled = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteCancelled(from: senderName)
            }
        }
    }
}
