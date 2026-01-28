//
//  RemoteVideoView.swift
//  App
//
//  Created by soyoung on 1/19/26.
//

import SwiftUI
import AVFoundation

final class VideoContainerView: UIView {
    
    var videoLayer: AVSampleBufferDisplayLayer?

    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override fuction

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let videoLayer = videoLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        videoLayer.frame = self.bounds
        videoLayer.bounds = self.bounds

        CATransaction.commit()
    }
    
    // MARK: - Private function
    
    private func setupView() {
        self.backgroundColor = .black
        self.layer.cornerRadius = 14
        self.clipsToBounds = true
    }
}

struct RemoteVideoView: UIViewRepresentable {

    let layer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> VideoContainerView {
        let containerView = VideoContainerView()

        setupLayer(layer)

        // 레이어를 containerView에 추가
        layer.frame = containerView.bounds
        layer.bounds = containerView.bounds
        containerView.layer.addSublayer(layer)
        containerView.videoLayer = layer

        containerView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()

        return containerView
    }

    func updateUIView(_ uiView: VideoContainerView, context: Context) {
        // 매 업데이트마다 레이어 동기화
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        layer.frame = uiView.bounds
        layer.bounds = uiView.bounds

        CATransaction.commit()

        if layer.superlayer == nil {
            uiView.layer.addSublayer(layer)
            uiView.videoLayer = layer
        }

        uiView.setNeedsLayout()
    }

    private func setupLayer(_ displayLayer: AVSampleBufferDisplayLayer) {
        displayLayer.videoGravity = .resizeAspectFill
        displayLayer.isHidden = false
        displayLayer.opacity = 1.0
        displayLayer.backgroundColor = UIColor.black.cgColor
        displayLayer.zPosition = 100
    }
}
