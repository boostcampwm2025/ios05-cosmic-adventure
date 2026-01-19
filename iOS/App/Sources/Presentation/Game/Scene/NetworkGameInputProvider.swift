//
//  NetworkGameInputProvider.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/19/26.
//

import Games
import Foundation

// MARK: - Network -> GameInputProviding adapter

/// 네트워크에서 받은 입력을 `GameInputProviding`으로 변환해 GameplayManager에 주입하기 위한 어댑터
final class NetworkGameInputProvider: GameInputProviding, @unchecked Sendable {
    // 단일 직렬 큐로 continuation 접근을 직렬화
    private let queue = DispatchQueue(label: "com.cosmicadventure.networkInputProvider")
    private var continuation: AsyncStream<GameInputEvent>.Continuation?
    private var token: UUID?

    func start() {
        // 수신 콜백에서 yield
    }

    func stop() {
        // 큐에서 안전하게 가져온 뒤 finish는 큐 밖에서 호출
        let cont: AsyncStream<GameInputEvent>.Continuation? = queue.sync {
            let cont = continuation
            continuation = nil
            token = nil
            return cont
        }
        cont?.finish()
    }

    func events() async -> AsyncStream<GameInputEvent> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let currentToken = UUID()

            // 단일 구독: 기존 continuation을 종료하고 새 continuation으로 교체
            let previous: AsyncStream<GameInputEvent>.Continuation? = self.queue.sync {
                let prev = self.continuation
                self.continuation = continuation
                self.token = currentToken
                return prev
            }
            previous?.finish()

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
              
                // 현재 토큰이 나의 토큰일 때만 정리
                self.queue.async {
                    if self.token == currentToken {
                        self.continuation = nil
                        self.token = nil
                    }
                }
            }
        }
    }

    func yield(_ event: GameInputEvent) {
        queue.async { [weak self] in
            self?.continuation?.yield(event)
        }
    }
}
