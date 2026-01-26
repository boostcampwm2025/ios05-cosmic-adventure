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
    private var isLowBitrateMode: Bool = false

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
        guard let peerName = self.peerName else { return }

        let currentLatency: Double = {
            if networkMode == .remote {
                return (webSocketSessionManager as? WebSocketSessionManager)?
                    .players.first { $0.nickname == peerName }?.latency ?? 150.0
            } else {
                return (networkSessionManager as? NetworkSessionManager)?
                    .nearbyPlayer.first { $0.name == peerName }?.latency ?? 50.0
            }
        }()

        // 모드에 따른 가변 기준점 설정
        // P2P는 150ms만 넘어도 이상 상태로 볼 수 있고, 서버는 300ms까지 정상으로 볼 수 있음.
        let highLatencyThreshold = (networkMode == .remote) ? 350.0 : 180.0
        let lowLatencyThreshold = (networkMode == .remote) ? 150.0 : 80.0

        if currentLatency > highLatencyThreshold {
            if !isLowBitrateMode {
                videoEncoder?.changeBitrate(to: configuration.lowBitrate)
                isLowBitrateMode = true
                logger.debug("[Latency] 지연 발생: 화질 낮춤")
            }
        } else if currentLatency < lowLatencyThreshold {
            if isLowBitrateMode {
                videoEncoder?.changeBitrate(to: configuration.highBitrate)
                isLowBitrateMode = false
                logger.debug("[Latency] 안정적: 화질 복구")

                reset(includePeer: false)
            }
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

    func reset(includePeer: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            if #available(iOS 18.0, *) {
                self?.remoteDisplayLayer.sampleBufferRenderer.flush()
            } else {
                self?.remoteDisplayLayer.flush()
            }
            self?.remoteDisplayLayer.controlTimebase = nil
        }

        videoDecoder?.reset()

        if includePeer {
            self.peerName = nil
        }

        setupEncoder()
    }

    func handleConnectivityChange(isConnected: Bool) {
        self.networkMode = isConnected ? .remote : .local
        logger.info("네트워크 모드 변경: \(self.networkMode == .remote ? "Remote" : "Local")")

        reset(includePeer: false)
        checkNetworkHealth()
    }
}
