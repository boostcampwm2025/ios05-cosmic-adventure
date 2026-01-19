//
//  VideoManager.swift
//  App
//
//  Created by soyoung on 1/19/26.
//

import AVFoundation
import NetworkKit

@Observable
public final class VideoManager {

    private let configuration: VideoConfiguration
    private var videoEncoder: VideoEncoder?
    private var videoDecoder: VideoDecoder?

    public let remoteDisplayLayer = AVSampleBufferDisplayLayer()
    private var latencyTimer: Timer?
    private var lastFrameTime: TimeInterval = 0

    private(set) var networkMode: NetworkMode = .local

    @ObservationIgnored
    var connectivityMonitor: ConnectivityMonitoring

    @ObservationIgnored
    var networkSessionManager: NetworkSessionManaging

    @ObservationIgnored
    let webSocketSessionManager: WebSocketSessionManaging?

    // MARK: - Init
    public init(connectivityMonitor: ConnectivityMonitoring,
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
        connectivityMonitor.onStatusChanged = { [weak self] isConnected in
            Task { @MainActor in
                self?.handleConnectivityChange(isConnected: isConnected)
            }
        }
        connectivityMonitor.start()
        networkMode = connectivityMonitor.isConnected ? .remote : .local
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
        // 상대방 영상 데이터 수신 -> 디코딩
        networkSessionManager.onVideoReceived = { [weak self] (_, data) in
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

    // 60fps로 들어오는 데이터는 PIP 용도로 너무 큼
    public func processFrame(pixelBuffer: CVPixelBuffer) {
        let currentTime = CACurrentMediaTime()

        // 목표 프레임 간격 계산 (1초 / 30fps = 0.0333초)
        let targetInterval = 1.0 / Double(configuration.frameRate)

        // 마지막 보낸 시간보다 0.033초가 안 지났으면
        if currentTime - lastFrameTime < targetInterval {
            return
        }

        // 시간 갱신하고 인코딩 시작
        lastFrameTime = currentTime
        videoEncoder?.encode(pixelBuffer: pixelBuffer)
    }
}
