//
//  VideoConfiguration.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import Foundation

public struct VideoConfiguration {
    // 인코딩 해상도 (픽셀 단위)
    public let resolutionWidth: Int32
    public let resolutionHeight: Int32

    // 화면 표시 크기 (포인트 단위)
    public let displaySize: CGFloat

    // 비트레이트 (네트워크 상태에 따른 화질)
    public let highBitrate: Int
    public let lowBitrate: Int

    // 화질 점검 및 키프레임 주기 설정 (복구용)
    public let monitoringInterval: Double

    // FPS, 키프레임 시간
    public let frameRate: Int32
    public let keyFrameIntervalDuration: Double

    // Latency 임계값
    public struct LatencyThresholds {
        public let high: Double
        public let low: Double
        public let defaultFallback: Double
    }

    // 원격(Remote) 모드용 임계값
    public let remoteThresholds = LatencyThresholds(
        high: 350.0,
        low: 150.0,
        defaultFallback: 150.0
    )

    // 로컬(Local/P2P) 모드용 임계값
    public let localThresholds = LatencyThresholds(
        high: 180.0,
        low: 80.0,
        defaultFallback: 50.0
    )

    public init(
        resolutionWidth: Int32 = 192,
        resolutionHeight: Int32 = 192,
        displaySize: CGFloat = 60.0,
        highBitrate: Int = 400_000,
        lowBitrate: Int = 100_000,
        monitoringInterval: Double = 2.0,
        frameRate: Int32 = 60,
        keyFrameIntervalDuration: Double = 1.0
    ) {
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.displaySize = displaySize
        self.highBitrate = highBitrate
        self.lowBitrate = lowBitrate
        self.monitoringInterval = monitoringInterval
        self.frameRate = frameRate
        self.keyFrameIntervalDuration = keyFrameIntervalDuration
    }
}
