//
//  LocalNetworkPermissionRequester.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

import NetworkKit

final class LocalNetworkPermissionRequester: LocalNetworkPermissionRequesting {

    private var networkSessionManager: NetworkSessionManaging

    init(networkSessionManager: NetworkSessionManaging) {
        self.networkSessionManager = networkSessionManager
    }

    /// 초기 권한 요청을 위한 임시 세션을 실행하고 결과를 반환합니다.
    func requestPermission(hostName: String) async -> Bool {
        return await AsyncStream { continuation in
            var timeoutTask: Task<Void, Never>?

            networkSessionManager.onPermissionResult = { [weak self] result in
                timeoutTask?.cancel()

                switch result {
                case .success:
                    continuation.yield(true)
                case .failure:
                    continuation.yield(false)
                }
                self?.networkSessionManager.deactivate()
                continuation.finish()
            }

            networkSessionManager.activate(channelId: nil, nickname: hostName, characterRawValue: "")

            // 초기 요청 시 응답이 없을 경우를 대비한 타임아웃
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                self?.networkSessionManager.deactivate()
                continuation.yield(false)
                continuation.finish()
            }
        }.first(where: { _ in true }) ?? false
    }
}
