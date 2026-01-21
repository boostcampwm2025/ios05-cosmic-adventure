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
    @State private var lastRawCenter: CGPoint? = nil

    @State private var isCollapsed: Bool = false
    @State private var collapsedEdge: CollapsedEdge = .trailing

    private enum CollapsedEdge {
        case leading
        case trailing
    }
    
    public enum SizeStyle {
        case small
        case medium
        case large
        
        public var pipSize: CGSize {
            switch self {
            case .small: return CGSize(width: 100, height: 130)
            case .medium: return CGSize(width: 140, height: 180)
            case .large: return CGSize(width: 180, height: 230)
            }
        }
        
        public init(from level: SettingsLevel) {
            switch level {
            case .low: self = .small
            case .medium: self = .medium
            case .high: self = .large
            }
        }
    }

    private let content: Content
    private let sizeStyle: SizeStyle
    
    public init(sizeStyle: SizeStyle = .medium, @ViewBuilder content: () -> Content) {
        self.sizeStyle = sizeStyle
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let defaultPadding = 25.0
            let containerSize = proxy.size
            let pipSize = sizeStyle.pipSize
            let defaultCenter = CGPoint(
                x: containerSize.width - pipSize.width / 2 - defaultPadding,
                y: containerSize.height - pipSize.height / 2 - defaultPadding
            )
            
            ZStack {
                if isCollapsed {
                    handleView(
                        safe: proxy.safeAreaInsets,
                        containerSize: containerSize,
                        pipSize: pipSize,
                        defaultCenter: defaultCenter
                    )
                } else {
                    pipView(
                        safe: proxy.safeAreaInsets,
                        containerSize: containerSize,
                        pipSize: pipSize,
                        defaultCenter: defaultCenter
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func pipView(
        safe: EdgeInsets,
        containerSize: CGSize,
        pipSize: CGSize,
        defaultCenter: CGPoint
    ) -> some View {
        let currentCenter = clampCenter(
            center ?? defaultCenter,
            containerSize: containerSize,
            safe: safe,
            pipSize: pipSize
        )

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

                    let raw = CGPoint(
                        x: start.x + value.translation.width,
                        y: start.y + value.translation.height
                    )
                    lastRawCenter = raw

                    center = clampCenter(
                        raw,
                        containerSize: containerSize,
                        safe: safe,
                        pipSize: pipSize
                    )
                }
                .onEnded { _ in
                    defer {
                        dragStartCenter = nil
                        lastRawCenter = nil
                    }

                    let thresholdX = pipSize.width * 0.1
                    if let raw = lastRawCenter {
                        if raw.x < -thresholdX {
                            collapsedEdge = .leading
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isCollapsed = true
                            }
                            return
                        }
                        if raw.x > containerSize.width + thresholdX {
                            collapsedEdge = .trailing
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isCollapsed = true
                            }
                            return
                        }
                    }

                    let clamped = clampCenter(
                        center ?? defaultCenter,
                        containerSize: containerSize,
                        safe: safe,
                        pipSize: pipSize
                    )

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        center = clamped
                    }
                }
        )
    }

    @ViewBuilder
    private func handleView(
        safe: EdgeInsets,
        containerSize: CGSize,
        pipSize: CGSize,
        defaultCenter: CGPoint
    ) -> some View {
        let handleSize = CGSize(width: 44, height: 44)
        let padding: CGFloat = 10

        let x: CGFloat = {
            switch collapsedEdge {
            case .leading:
                return safe.leading + handleSize.width / 2 + padding
            case .trailing:
                return containerSize.width - safe.trailing - handleSize.width / 2 - padding
            }
        }()

        let preferredY = (center ?? defaultCenter).y
        let minY = safe.top + handleSize.height / 2 + padding
        let maxY = containerSize.height - safe.bottom - handleSize.height / 2 - padding
        let y = min(max(preferredY, minY), maxY)

        Button {
            let restoredX: CGFloat = {
                let pipPadding: CGFloat = 12
                switch collapsedEdge {
                case .leading:
                    return safe.leading + pipSize.width / 2 + pipPadding
                case .trailing:
                    return containerSize.width - safe.trailing - pipSize.width / 2 - pipPadding
                }
            }()

            let restored = clampCenter(
                CGPoint(x: restoredX, y: y),
                containerSize: containerSize,
                safe: safe,
                pipSize: pipSize
            )

            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isCollapsed = false
                center = restored
            }
        } label: {
            Image(systemName: "video.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: handleSize.width, height: handleSize.height)
                .background(.black.opacity(0.65))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(radius: 4)
        }
        .position(x: x, y: y)
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
