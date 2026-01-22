//
//  PermissionService.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

import AVFoundation
import NetworkKit
import UIKit

final class DefaultPermissionService: PermissionServicing {
    private let localNetworkRequester: LocalNetworkPermissionRequesting
    private let notificationRequester: NotificationPermissionRequesting

    init(localNetworkRequester: LocalNetworkPermissionRequesting,
         notificationRequester: NotificationPermissionRequesting
    ) {
        self.localNetworkRequester = localNetworkRequester
        self.notificationRequester = notificationRequester
    }

    func refreshCameraState() -> PermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .allowed
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func requestCameraIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let granted = await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { cont.resume(returning: $0) }
            }
            return granted
        @unknown default:
            return false
        }
    }

    func requestLocalNetworkPermissionIfNeeded() async -> Bool {
        let isGranted = await localNetworkRequester.requestPermission(hostName: "permission-check")
        return isGranted
    }

    func requestNotificationPermission() async -> Bool {
        let isGranted = await notificationRequester.requestPermission()
        return isGranted
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
