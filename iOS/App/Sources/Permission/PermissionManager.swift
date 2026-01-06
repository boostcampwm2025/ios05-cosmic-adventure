//
//  PermissionManager.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import AVFoundation
import Foundation
import UIKit

// TODO: 네트워크 권한은 "확인/요청" API가 없어서 실제 구현은 나중에 붙이기.
protocol LocalNetworkPermissionRequesting {
    func requestPermission() async -> Bool
}

final class StubLocalNetworkPermissionRequester: LocalNetworkPermissionRequesting {
    func requestPermission() async -> Bool {
        true
    }
}

@MainActor
final class PermissionManager: ObservableObject {

    enum PermissionState {
        case unknown
        case allowed
        case denied
    }

    @Published private(set) var cameraState: PermissionState = .unknown
    @Published private(set) var localNetworkState: PermissionState = .unknown

    @Published var showSettingsAlert: Bool = false
    @Published var settingsAlertMessage: String = ""

    // TODO: 이걸로 navigaion 연결하기
    @Published var shouldNavigateNext: Bool = false

    private let localNetworkRequester: LocalNetworkPermissionRequesting

    // 나중에 Bonjour browse/advertise로 팝업 트리거
    init(localNetworkRequester: LocalNetworkPermissionRequesting = StubLocalNetworkPermissionRequester()) {
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
        let ok = await localNetworkRequester.requestPermission()
        localNetworkState = ok ? .allowed : .denied
        return ok
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
