//
//  RemoteVideoView.swift
//  App
//
//  Created by soyoung on 1/19/26.
//

import SwiftUI
import ARKit

public struct RemoteVideoView: UIViewRepresentable {
    public let layer: AVSampleBufferDisplayLayer

    public init(layer: AVSampleBufferDisplayLayer) {
        self.layer = layer
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            layer.frame = uiView.bounds
        }
    }
}
