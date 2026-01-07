//
//  PermissionManager.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import AVFoundation
import NetworkKit
import Observation
import UIKit

protocol LocalNetworkPermissionRequesting {
    func requestPermission() async -> Bool
}

final class StubLocalNetworkPermissionRequester: LocalNetworkPermissionRequesting {
    func requestPermission() async -> Bool {
        true
    }
}

final class LocalNetworkPermissionRequester: LocalNetworkPermissionRequesting {
    private let sessionProvider = NetworkSessionManager()

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            var hasResumed = false

            sessionProvider.onLocalNetworkPermissionGranted = {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: true)
            }

            sessionProvider.onLocalNetworkPermissionDenied = { _ in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: false)
            }

            // TODO: - 실제 사용자 닉네임으로 수정
            sessionProvider.activate(nickname: "permission-check")
        }
    }
}

@MainActor
@Observable
final class PermissionManager {

    enum PermissionState {
        case unknown
        case allowed
        case denied
    }

    private(set) var cameraState: PermissionState = .unknown
    private(set) var localNetworkState: PermissionState = .unknown

    var showSettingsAlert: Bool = false
    var settingsAlertMessage: String = ""

    // TODO: 이걸로 navigaion 연결하기
    var shouldNavigateNext: Bool = false

    @ObservationIgnored
    private let localNetworkRequester: LocalNetworkPermissionRequesting

    init(localNetworkRequester: LocalNetworkPermissionRequesting) {
        self.localNetworkRequester = localNetworkRequester
        refreshCameraState()
    }

    func refreshCameraState() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: cameraState = .allowed
        case .denied, .restricted: cameraState = .denied
        case .notDetermined: cameraState = .unknown
        @unknown default: cameraState = .unknown
        }
    }

    func requestPermissionsOnNextTapped() async {
        // 1) 카메라
        let camOK = await requestCameraIfNeeded()
        guard camOK else {
            settingsAlertMessage = "카메라 권한이 필요해요. 설정에서 카메라 접근을 허용해 주세요."
            showSettingsAlert = true
            return
        }

        // 2) 로컬 네트워크
        let localOK = await requestLocalNetworkPermissionIfNeeded()
        guard localOK else {
            settingsAlertMessage = "근거리 통신(로컬 네트워크) 권한이 필요해요. 설정에서 로컬 네트워크 접근을 허용해 주세요."
            showSettingsAlert = true
            return
        }
        
        if cameraState == .allowed && localNetworkState == .allowed {
            shouldNavigateNext = true
        }
    }

    private func requestCameraIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraState = .allowed
            return true
        case .denied, .restricted:
            cameraState = .denied
            return false
        case .notDetermined:
            let granted = await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { cont.resume(returning: $0) }
            }
            cameraState = granted ? .allowed : .denied
            return granted
        @unknown default:
            cameraState = .unknown
            return false
        }
    }

    private func requestLocalNetworkPermissionIfNeeded() async -> Bool {
        let isGranted = await localNetworkRequester.requestPermission()
        localNetworkState = isGranted ? .allowed : .denied
        return isGranted
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
