//
//  VideoManager.swift
//  App
//
//  Created by soyoung on 1/19/26.
//

import AVFoundation
import VideoKit
import NetworkKit
import os

public final class VideoManager {

    private let configuration: VideoConfiguration
    private var videoEncoder: (any VideoEncoding)?
    private var videoDecoder: (any VideoDecoding)?

    private var latencyTimer: Timer?
    private var lastFrameTime: TimeInterval = 0

    lazy var remoteDisplayLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        let size = configuration.displaySize

        layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        layer.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        layer.videoGravity = .resizeAspectFill
        let address = Unmanaged.passUnretained(layer).toOpaque()
        return layer
    }()

    private(set) var networkMode: NetworkMode = .local

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring

    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?

    private let logger = Logger(subsystem: "com.cosmicadventure.Game", category: "VideoManager")

    init(connectivityMonitor: ConnectivityMonitoring,
         networkSessionManager: NetworkSessionManaging,
         webSocketSessionManager: WebSocketSessionManaging?,
         configuration: VideoConfiguration = VideoConfiguration()
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.configuration = configuration

        setupConnectivityMonitor()
        setupEncoder()
        setupDecoder()
        setupVideoDataCallbacks()
        startLatencyMonitor()
    }

    deinit {
        latencyTimer?.invalidate()
    }

    private func setupConnectivityMonitor() {
        // TODO: lobbyViewModel의 networkMode 전달 받아야 함.
        //        connectivityMonitor.onStatusChanged = { [weak self] isConnected in
        //            Task { @MainActor in
        //                self?.handleConnectivityChange(isConnected: isConnected)
        //            }
        //        }
        //        connectivityMonitor.start()
        //        networkMode = connectivityMonitor.isConnected ? .remote : .local
        networkMode = .local
    }

    private func handleConnectivityChange(isConnected: Bool) {
        if isConnected {
            networkMode = .remote
        } else {
            networkMode = .local
        }
    }

    private func setupEncoder() {
        self.videoEncoder = VideoEncoder(configuration: self.configuration)

        self.videoEncoder?.output = { [weak self] data in
            guard let self else { return }
            handleEncodedData(data: data)
        }
    }

    // 압축된 데이터 전송
    private func handleEncodedData(data: Data) {
        let sendLog = data.prefix(10).map { String(format: "%02x", $0) }.joined()
        logger.info("[전송] 크기: \(data.count) bytes | 헤더: \(sendLog)")

        switch networkMode {
        case .local:
            networkSessionManager.sendVideo(data: data)

        case .remote:
            webSocketSessionManager?.sendVideo(data: data)
        }
    }

    private func setupDecoder() {
        self.videoDecoder = VideoDecoder(configuration: self.configuration)
        self.videoDecoder?.displayLayer = self.remoteDisplayLayer
    }

    private func setupVideoDataCallbacks() {
        networkSessionManager.onVideoReceived = { [weak self] (_, data) in
            self?.logger.info("[VideoManager] 비디오 데이터 수신: \(data.count) bytes, decoder=\(self?.videoDecoder != nil)")
            self?.videoDecoder?.decode(data: data)
        }

        webSocketSessionManager?.onVideoReceived = { [weak self] (_, data) in
            self?.videoDecoder?.decode(data: data)
        }
    }

    // Network Adaptation
    private func startLatencyMonitor() {
        latencyTimer = Timer.scheduledTimer(withTimeInterval: configuration.monitoringInterval, repeats: true) { [weak self] _ in
            self?.checkNetworkHealth()
        }
    }

    private func checkNetworkHealth() {
        // TODO: 실제 'Ping & Pong'값 연동 (임시 랜덤값)
        let latency = Double.random(in: 50...400)

        if latency > 300 {
            // 화질 낮춤 (100kbps)
            videoEncoder?.changeBitrate(to: configuration.lowBitrate)
        } else if latency < 150 {
            // 화질 높임 (300kbps)
            videoEncoder?.changeBitrate(to: configuration.highBitrate)
        }
    }

    func processFrame(pixelBuffer: CVPixelBuffer) {
        videoEncoder?.encode(pixelBuffer: pixelBuffer)
    }
}
