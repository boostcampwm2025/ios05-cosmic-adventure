//
//  FacePreviewView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI
import ARKit

public struct FacePreviewView: UIViewRepresentable {
    public let session: ARSession

    public init(session: ARSession) { self.session = session }

    public func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        return view
    }

    public func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
