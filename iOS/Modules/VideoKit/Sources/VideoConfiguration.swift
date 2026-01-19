//
//  VideoConfig.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

public struct VideoConfiguration {

    // 해상도
    public let width: Int32
    public let height: Int32

    // 비트레이트 (네트워크 상태에 따른 화질)
    public let highBitrate: Int
    public let lowBitrate: Int

    // 화질 점검 및 키프레임 주기 설정 (복구용)
    public let monitoringInterval: Double

    // FPS, 키프레임 시간
    public let frameRate: Int32
    public let keyFrameIntervalDuration: Double

    public init(
        width: Int32 = 192,
        height: Int32 = 192, // PIP용 저해상도
        highBitrate: Int = 150_000,
        lowBitrate: Int = 60_000,
        monitoringInterval: Double = 2.0,
        frameRate: Int32 = 30,
        keyFrameIntervalDuration: Double = 2.0
    ) {
        self.width = width
        self.height = height
        self.highBitrate = highBitrate
        self.lowBitrate = lowBitrate
        self.monitoringInterval = monitoringInterval
        self.frameRate = frameRate
        self.keyFrameIntervalDuration = keyFrameIntervalDuration
    }
}
