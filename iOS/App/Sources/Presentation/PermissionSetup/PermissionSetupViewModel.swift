//
//  PermissionSetupViewModel.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import Observation
import UIKit

public enum PermissionState: String, Codable {
    case unknown
    case allowed
    case denied
}

@MainActor
@Observable
final class PermissionSetupViewModel {

    // MARK: - Properties

    private let service: PermissionServicing

    private(set) var cameraState: PermissionState = .unknown
    private(set) var localNetworkState: PermissionState = .unknown

    var showSettingsAlert: Bool = false
    var settingsAlertMessage: String = ""

    /// View에서 관찰하여 다음 화면으로 이동시키기 위한 플래그
    var shouldNavigateNext: Bool = false

    init(service: PermissionServicing) {
        self.service = service
        self.cameraState = service.refreshCameraState()
    }

    func refreshPermissionStates() {
        cameraState = service.refreshCameraState()
    }

    func onNextTapped() async {
        // 1) 카메라
        guard await service.requestCameraIfNeeded() else {
            cameraState = .denied
            settingsAlertMessage = "카메라 권한이 필요해요. 설정에서 카메라 접근을 허용해 주세요."
            showSettingsAlert = true
            return
        }
        cameraState = .allowed

        // 2) 로컬 네트워크
        guard await service.requestLocalNetworkPermissionIfNeeded() else {
            localNetworkState = .denied
            settingsAlertMessage = "근거리 통신(로컬 네트워크) 권한이 필요해요. 설정에서 로컬 네트워크 접근을 허용해 주세요."
            showSettingsAlert = true
            return
        }
        localNetworkState = .allowed
        
        UserDefaultsList.Permission.hasCompletedPermissionSetup = true
        shouldNavigateNext = true
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
