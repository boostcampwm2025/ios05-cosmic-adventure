//
//  LocalNetworkPermissionRequester.swift
//  App
//
//  Created by 강윤서 on 1/8/26.
//

import Foundation
import NetworkKit

protocol LocalNetworkPermissionRequesting {
    func requestPermission(hostName: String) async -> Bool
}

final class LocalNetworkPermissionRequester: LocalNetworkPermissionRequesting {
    
    private var sessionProvider: ConnectionSessionProvider
    
    init(sessionProvider: ConnectionSessionProvider = NetworkSessionManager()) {
        self.sessionProvider = sessionProvider
    }
    
    /// 초기 권한 요청을 위한 임시 세션을 실행하고 결과를 반환합니다.
    func requestPermission(hostName: String) async -> Bool {
        await AsyncStream { continuation in
            sessionProvider.onPermissionResult = { result in
                switch result {
                case .success:
                    continuation.yield(true)
                case .failure:
                    continuation.yield(false)
                }
                continuation.finish()
            }
            
            sessionProvider.activate(nickname: hostName)
            
            // 초기 요청 시 응답이 없을 경우를 대비한 타임아웃
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                continuation.yield(false)
                continuation.finish()
            }
        }.first(where: { _ in true }) ?? false
    }
}
