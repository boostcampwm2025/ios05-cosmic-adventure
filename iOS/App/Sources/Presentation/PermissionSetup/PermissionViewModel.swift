//
//  PermissionManager.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import AVFoundation
import Observation
import UIKit

public enum PermissionState: String, Codable {
    case unknown
    case allowed
    case denied
}

@MainActor
@Observable
final class PermissionViewModel {

    // MARK: - Properties

    private(set) var cameraState: PermissionState = .unknown
    private(set) var localNetworkState: PermissionState = .unknown

    var showSettingsAlert: Bool = false
    var settingsAlertMessage: String = ""

    // TODO: 이걸로 navigaion 연결하기
    var shouldNavigateNext: Bool = false

    @ObservationIgnored
    private let localNetworkRequester: LocalNetworkPermissionRequesting

    // MARK: - Initialization
    
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
            UserDefaultsList.Permission.cameraPermission = true
            return true
        case .denied, .restricted:
            cameraState = .denied
            UserDefaultsList.Permission.cameraPermission = false
            return false
        case .notDetermined:
            let granted = await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { cont.resume(returning: $0) }
            }
            cameraState = granted ? .allowed : .denied
            UserDefaultsList.Permission.cameraPermission = granted
            return granted
        @unknown default:
            cameraState = .unknown
            UserDefaultsList.Permission.cameraPermission = false
            return false
        }
    }

    private func requestLocalNetworkPermissionIfNeeded() async -> Bool {
        let isGranted = await localNetworkRequester.requestPermission(hostName: "permission-check")
        localNetworkState = isGranted ? .allowed : .denied
        UserDefaultsList.Permission.localNetworkPermission = isGranted
        return isGranted
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
