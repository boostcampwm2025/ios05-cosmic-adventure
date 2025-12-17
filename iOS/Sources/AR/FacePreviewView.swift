//
//  FacePreviewView.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/16/25.
//
import SwiftUI
import ARKit

struct FacePreviewView: UIViewRepresentable {
    
    let session: ARSession
    
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
