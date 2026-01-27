//
//  AppEntryManager.swift
//  App
//
//  Created by 영빈 on 1/22/26.
//

import Observation

enum PermissionAlertKind {
    case localNetworkDenied
    case cameraDenied
}

@MainActor
@Observable
final class AppEntryManager {
    private let permissionService: PermissionServicing

    var activePermissionAlert: PermissionAlertKind?

    init(permissionService: PermissionServicing) {
        self.permissionService = permissionService
    }
    
    func presentAlert(_ kind: PermissionAlertKind) {
        activePermissionAlert = kind
    }
    
    func dismissAlert() {
        activePermissionAlert = nil
    }
    
    func openAppSettings() {
        permissionService.openAppSettings()
    }
    
    func isLocalNetworkPermissionGranted() async -> Bool {
        return await permissionService.requestLocalNetworkPermissionIfNeeded()
    }
    
    func checkCameraPermission() async -> Bool {
        let cameraState = permissionService.refreshCameraState()
        switch cameraState {
        case .allowed:
            return true
        case .denied:
            return false
        case .unknown:
            return await permissionService.requestCameraIfNeeded()
        }
    }
    
    func canEnterGame() async -> Bool {
        guard activePermissionAlert == nil else { return false }
        
        let cameraAllowed = await checkCameraPermission()
        guard cameraAllowed else {
            presentAlert(.cameraDenied)
            return false
        }
        
        return true
    }
}
