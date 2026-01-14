//
//  FacePreviewPIPView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/14/26.
//

import SwiftUI

public struct FacePreviewPIPView<Content: View>: View {
    @State private var center: CGPoint? = nil
    @State private var dragStartCenter: CGPoint? = nil
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let defaultPadding = 25.0
            let containerSize = proxy.size
            let pipSize = CGSize(width: 140, height: 180)
            let defaultCenter = CGPoint(
                x: containerSize.width - pipSize.width / 2 - defaultPadding,
                y: containerSize.height - pipSize.height / 2 - defaultPadding
            )
            
            let currentCenter = center ?? defaultCenter
            
            ZStack {
                content
                    .allowsHitTesting(false)
            }
            .frame(width: pipSize.width, height: pipSize.height)
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(radius: 6)
            .position(currentCenter)
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if dragStartCenter == nil {
                            dragStartCenter = center ?? defaultCenter
                        }
                        let start = dragStartCenter ?? defaultCenter
                        let proposed = CGPoint(
                            x: start.x + value.translation.width,
                            y: start.y + value.translation.height
                        )
                        center = clampCenter(
                            proposed,
                            containerSize: containerSize,
                            safe: proxy.safeAreaInsets,
                            pipSize: pipSize
                        )
                    }
                    .onEnded { _ in
                        defer { dragStartCenter = nil }

                        let clamped = clampCenter(
                            center ?? defaultCenter,
                            containerSize: containerSize,
                            safe: proxy.safeAreaInsets,
                            pipSize: pipSize
                        )

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            center = clamped
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }
    
    private func clampCenter(
        _ point: CGPoint,
        containerSize: CGSize,
        safe: EdgeInsets,
        pipSize: CGSize
    ) -> CGPoint {
        let padding: CGFloat = 12
        let minX = safe.leading + pipSize.width / 2 + padding
        let maxX = containerSize.width - safe.trailing - pipSize.width / 2 - padding
        let minY = safe.top + pipSize.height / 2 + padding
        let maxY = containerSize.height - safe.bottom - pipSize.height / 2 - padding
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }
}
