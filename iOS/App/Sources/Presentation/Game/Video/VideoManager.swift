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
        createCleanDisplayLayer()
    }()

    private(set) var remotePlayer: PlayerInfo?
    private(set) var networkMode: NetworkMode = .local

    private let networkSessionManager: ConnectionSessionManaging
    private let webSocketSessionManager: ConnectionSessionManaging?

    private let logger = Logger(subsystem: "com.cosmicadventure.Game", category: "VideoManager")

    init(networkSessionManager: ConnectionSessionManaging,
         webSocketSessionManager: ConnectionSessionManaging?,
         configuration: VideoConfiguration = VideoConfiguration()
    ) {
        self.networkSessionManager = networkSessionManager
        self.webSocketSessionManager = webSocketSessionManager
        self.configuration = configuration

        setupEncoder()
        setupDecoder()
        setupVideoDataCallbacks()
    }

    deinit {
        stopLatencyMonitoring()
        videoEncoder?.invalidate()
    }

    private func createCleanDisplayLayer() -> AVSampleBufferDisplayLayer {
        let layer = AVSampleBufferDisplayLayer()
        let size = configuration.displaySize

        layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        layer.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        layer.videoGravity = .resizeAspectFill
        return layer
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
        guard let target = remotePlayer else { return }
        connectionSessionManager?.sendVideo(data, to: target.id)
    }

    private func setupDecoder() {
        self.videoDecoder = VideoDecoder()
        self.videoDecoder?.setDisplayLayer(self.remoteDisplayLayer)
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
        guard let target = self.remotePlayer else { return }

        let thresholds = (networkMode == .remote) ? configuration.remoteThresholds : configuration.localThresholds
        let sessionManager = (networkMode == .remote) ? webSocketSessionManager : networkSessionManager

        let currentLatency = sessionManager?.getLatency(for: target.id) ?? thresholds.defaultFallback

        if currentLatency > thresholds.high {
            if !isLowBitrateMode {
                videoEncoder?.changeBitrate(to: configuration.lowBitrate)
                isLowBitrateMode = true
                logger.debug("[Latency] \(currentLatency)ms - 화질 낮춤")
            }
        } else if currentLatency < thresholds.low {
            if isLowBitrateMode {
                videoEncoder?.changeBitrate(to: configuration.highBitrate)
                isLowBitrateMode = false
                logger.debug("[Latency] \(currentLatency)ms - 화질 복구")
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

    func setTargetPlayer(_ remotePlayer: PlayerInfo?) {
        self.remotePlayer = remotePlayer
    }

    func processFrame(pixelBuffer: CVPixelBuffer) {
        videoEncoder?.encode(pixelBuffer: pixelBuffer)
    }

    func reset() {
        videoEncoder?.invalidate()
        videoEncoder = nil

        videoDecoder?.reset()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let oldLayer = remoteDisplayLayer
            oldLayer.removeFromSuperlayer()

            if #available(iOS 18.0, *) {
                oldLayer.sampleBufferRenderer.flush()
                oldLayer.sampleBufferRenderer.stopRequestingMediaData()
            } else {
                oldLayer.flushAndRemoveImage()
                oldLayer.stopRequestingMediaData()
            }

            oldLayer.controlTimebase = nil

            let newLayer = self.createCleanDisplayLayer()
            remoteDisplayLayer = newLayer
            videoDecoder?.setDisplayLayer(newLayer)
        }

        isLowBitrateMode = false
        self.remotePlayer = nil

        setupEncoder()
    }

    func setNetworkMode(isNetwork: Bool) {
        self.networkMode = isNetwork ? .remote : .local
        logger.info("네트워크 모드 변경: \(self.networkMode == .remote ? "Remote" : "Local")")

        checkNetworkHealth()
    }
}
