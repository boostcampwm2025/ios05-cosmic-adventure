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
        sessionManager.onPermissionResult = { [weak self] result in
            guard case .failure(let error) = result else { return }
            
            Task { @MainActor in 
                self?.activeAlert = (error == .denied) ? .permissionDenied : .unknownNetworkError
            }
        }
    }

    func setupP2PCallbacks() {
        sessionManager.onInviteReceived = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteReceived(from: senderName)
            }
        }

        sessionManager.onInviteAccepted = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteAccepted(from: senderName)
            }
        }

        sessionManager.onInviteDeclined = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteDeclined(from: senderName)
            }
        }

        sessionManager.onInviteCancelled = { [weak self] senderName in
            Task { @MainActor in
                self?.handleInviteCancelled(from: senderName)
            }
        }
    }
}
