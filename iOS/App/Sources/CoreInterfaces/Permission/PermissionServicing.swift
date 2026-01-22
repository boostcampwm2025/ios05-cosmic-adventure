//
//  PermissionServicing.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

@MainActor
protocol PermissionServicing {
    func refreshCameraState() -> PermissionState
    func requestCameraIfNeeded() async -> Bool
    func requestLocalNetworkPermissionIfNeeded() async -> Bool
    func requestNotificationPermission() async -> Bool
    func openAppSettings()
}
