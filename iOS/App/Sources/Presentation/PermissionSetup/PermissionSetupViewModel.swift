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

    @ObservationIgnored
    private let appEntryManager: AppEntryManager

    private(set) var cameraState: PermissionState = .unknown
    private(set) var localNetworkState: PermissionState = .unknown
    private(set) var notificationState: PermissionState = .unknown

    /// View에서 관찰하여 다음 화면으로 이동시키기 위한 플래그
    var shouldNavigateNext: Bool = false

    init(service: PermissionServicing, appEntryManager: AppEntryManager) {
        self.service = service
        self.appEntryManager = appEntryManager
        self.cameraState = service.refreshCameraState()
    }

    func refreshPermissionStates() {
        cameraState = service.refreshCameraState()
    }

    func onNextTapped() async {
        // 1) 카메라
        let cameraGranted = await service.requestCameraIfNeeded()
        cameraState = cameraGranted ? .allowed : .denied
        
        // 2) 로컬 네트워크
        let localNetworkGranted = await service.requestLocalNetworkPermissionIfNeeded()
        localNetworkState = localNetworkGranted ? .allowed : .denied
        
        // 3) 알림 (request but don't block)
        let notificationGranted = await service.requestNotificationPermission()
        notificationState = notificationGranted ? .allowed : .denied
        
        // 4) 둘 다 허용되면 설정 완료 표시
        if cameraGranted && localNetworkGranted {
            UserDefaultsList.Permission.hasCompletedPermissionSetup = true
        }
        
        // 5) 거부된 권한이 있으면 전역 알림 표시 (이동은 차단하지 않음)
        if !cameraGranted {
            appEntryManager.presentAlert(.cameraDenied)
        } else if !localNetworkGranted {
            appEntryManager.presentAlert(.localNetworkDenied)
        }
        
        // 6) 항상 프로필 설정으로 이동 허용
        shouldNavigateNext = true
    }


}
