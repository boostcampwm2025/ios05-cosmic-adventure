//
//  AppContainer.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

import Foundation
import NetworkKit

@MainActor
protocol ViewModelFactory {
    func makePermissionSetupViewModel() -> PermissionSetupViewModel
    func makeProfileSetupViewModel() -> ProfileSetupViewModel
    func makeLobbyViewModel() -> LobbyViewModel
}

final class AppContainer: ViewModelFactory {
    private let permissionService: PermissionServicing

    private let networkSessionManager: NetworkSessionManager
    // TODO: 유저 프로필 관리 객체 소유
    
    init(
        permissionService: PermissionServicing? = nil,
        networkSessionManager: NetworkSessionManager = NetworkSessionManager()
    ) {
        self.networkSessionManager = networkSessionManager
        self.permissionService = permissionService
            ?? DefaultPermissionService(
                localNetworkRequester: LocalNetworkPermissionRequester(
                    sessionProvider: networkSessionManager
                )
            )
    }
    
    func makePermissionSetupViewModel() -> PermissionSetupViewModel {
        PermissionSetupViewModel(service: permissionService)
    }
    
    func makeProfileSetupViewModel() -> ProfileSetupViewModel {
        ProfileSetupViewModel()
    }
    
    func makeLobbyViewModel() -> LobbyViewModel {
        LobbyViewModel(sessionManager: networkSessionManager)
    }

    // TODO: 게임 화면 서비스 객체 연결

    // TODO: 게임 결과 화면 뷰모델 생성

}
