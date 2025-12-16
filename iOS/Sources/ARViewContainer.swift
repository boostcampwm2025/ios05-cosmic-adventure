//
//  ARViewContainer.swift
//  iOS
//
//  Created by soyoung on 12/16/25.
//

import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var session: ARSession

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()

        arView.session = session
        arView.isHidden = false // 카메라는 보여야 하니까 false

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

