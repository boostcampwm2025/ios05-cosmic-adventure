//
//  AppEntryManager.swift
//  App
//
//  Created by 영빈 on 1/22/26.
//

@MainActor
final class AppEntryManager {
    private let permissionService: PermissionServicing

    init(permissionService: PermissionServicing) {
        self.permissionService = permissionService
    }

    func canEnterApp() async -> Bool {
        let cameraState = permissionService.refreshCameraState()
        switch cameraState {
        case .allowed:
            break
        case .denied:
            return false
        case .unknown:
            let granted = await permissionService.requestCameraIfNeeded()
            guard granted else { return false }
        }

        return await permissionService.requestLocalNetworkPermissionIfNeeded()
    }
}
