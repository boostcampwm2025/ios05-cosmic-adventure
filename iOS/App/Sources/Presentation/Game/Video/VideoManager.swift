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
        return layer
    }()

    private(set) var peerName: String?
    private(set) var networkMode: NetworkMode = .local

    private let networkSessionManager: ConnectionSessionManaging
    private let webSocketSessionManager: ConnectionSessionManaging?
    var connectivityMonitor: ConnectivityMonitoring

    private let logger = Logger(subsystem: "com.cosmicadventure.Game", category: "VideoManager")

    init(connectivityMonitor: ConnectivityMonitoring,
         networkSessionManager: ConnectionSessionManaging,
         webSocketSessionManager: ConnectionSessionManaging?,
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
    }

    deinit {
        stopLatencyMonitoring()
        videoEncoder?.invalidate()
    }

    private func setupConnectivityMonitor() {
        connectivityMonitor.onStatusChanged = { [weak self] isConnected in
            Task { @MainActor in
                self?.handleConnectivityChange(isConnected: isConnected)
            }
        }
        connectivityMonitor.start()
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
        logger.debug("[전송] 크기: \(data.count) bytes | 헤더: \(sendLog)")

        let connectionSessionManager = (networkMode == .remote) ? webSocketSessionManager : networkSessionManager
        connectionSessionManager?.sendVideo(data, to: peerName)
    }

    private func setupDecoder() {
        self.videoDecoder = VideoDecoder()
        self.videoDecoder?.displayLayer = self.remoteDisplayLayer
    }

    private func setupVideoDataCallbacks() {
        networkSessionManager.onVideoReceived = { [weak self] (_, data) in
            self?.logger.debug("[VideoManager] 비디오 데이터 수신: \(data.count) bytes, decoder=\(self?.videoDecoder != nil)")
            self?.videoDecoder?.decode(data: data)
        }

        webSocketSessionManager?.onVideoReceived = { [weak self] (_, data) in
            self?.logger.debug("[VideoManager] 비디오 데이터 수신: \(data.count) bytes, decoder=\(self?.videoDecoder != nil)")
            self?.videoDecoder?.decode(data: data)
        }
    }

    // Network Adaptation
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

    func startLatencyMonitoring() {
        latencyTimer?.invalidate()

        let timer = Timer(timeInterval: configuration.monitoringInterval, repeats: true) { [weak self] _ in
            self?.checkNetworkHealth()
        }

        RunLoop.main.add(timer, forMode: .common)

        self.latencyTimer = timer
    }

    func stopLatencyMonitoring() {
        latencyTimer?.invalidate()
        latencyTimer = nil
    }

    public func setTargetPlayer(nickName: String?) {
        self.peerName = nickName
    }

    func processFrame(pixelBuffer: CVPixelBuffer) {
        videoEncoder?.encode(pixelBuffer: pixelBuffer)
    }

    public func reset() {
        DispatchQueue.main.async { [weak self] in
            if #available(iOS 18.0, *) {
                self?.remoteDisplayLayer.sampleBufferRenderer.flush()
            } else {
                self?.remoteDisplayLayer.flush()
            }
            self?.remoteDisplayLayer.controlTimebase = nil
        }

        videoDecoder?.reset()
        self.peerName = nil
        self.lastFrameTime = 0
        setupEncoder()
    }

    func handleConnectivityChange(isConnected: Bool) {
        self.networkMode = isConnected ? .remote : .local
        logger.info("네트워크 모드 변경: \(self.networkMode == .remote ? "Remote" : "Local")")
    }
}
