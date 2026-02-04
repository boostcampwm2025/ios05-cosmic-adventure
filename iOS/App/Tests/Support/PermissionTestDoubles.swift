//
//  PermissionTestDoubles.swift
//  App
//
//  Created by 영빈 on 2/5/26.
//

import Foundation
@testable import App

@MainActor
struct MockPermissionService: PermissionServicing {
    var localNetworkResult: Bool = true
    var cameraResult: Bool = true

    func refreshCameraState() -> PermissionState { .allowed }
    func requestCameraIfNeeded() async -> Bool { cameraResult }
    func requestLocalNetworkPermissionIfNeeded() async -> Bool { localNetworkResult }
    func requestNotificationPermission() async -> Bool { true }
    func openAppSettings() {}
}
