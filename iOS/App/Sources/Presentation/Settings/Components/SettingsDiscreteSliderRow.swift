//
//  SettingsDiscreteSliderRow.swift
//  App
//
//  Created by 영빈 on 1/21/26.
//

import SwiftUI

struct SettingsDiscreteSliderRow: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let labels: [LocalizedStringKey]
    
    private var stepCount: Int { max(labels.count - 1, 1) }
    @State private var previousValue: Int?
    @State private var isDragging = false
    
    private let sliderBackground = AppAsset.Color.sheetSubBackground.swiftUIColor
    private let trackColor = AppAsset.Color.sliderTrack.swiftUIColor
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 18))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            
            discreteSliderTrack
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(sliderBackground)
                .clipShape(Capsule())
            
            SettingsSliderLabelRow(labels: labels, textColor: AppAsset.Color.mainLabel.swiftUIColor)
        }
        .onAppear { previousValue = value }
    }
    
    private var discreteSliderTrack: some View {
        GeometryReader { geometry in
            let thumbRadius: CGFloat = 14
            let trackWidth = geometry.size.width - thumbRadius * 2
            let stepWidth = trackWidth / CGFloat(stepCount)
            let thumbX = thumbRadius + CGFloat(value) * stepWidth
            
            ZStack {
                Capsule()
                    .fill(trackColor)
                    .frame(width: trackWidth, height: 6)
                    .position(x: geometry.size.width / 2, y: 14)
                
                ForEach(0...stepCount, id: \.self) { index in
                    let x = thumbRadius + CGFloat(index) * stepWidth
                    Circle()
                        .fill(trackColor)
                        .frame(width: 24, height: 24)
                        .position(x: x, y: 14)
                }
                
                Circle()
                    .fill(AppAsset.Color.subButton.swiftUIColor)
                    .frame(width: 28, height: 28)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .position(x: thumbX, y: 14)
                    .animation(.easeInOut(duration: 0.1), value: isDragging)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging { isDragging = true }
                        
                        let adjustedX = gesture.location.x - thumbRadius
                        let newValue = Int(round(adjustedX / stepWidth))
                        let clampedValue = min(max(newValue, 0), stepCount)
                        
                        if clampedValue != previousValue {
                            feedbackGenerator.impactOccurred()
                            previousValue = clampedValue
                        }
                        
                        value = clampedValue
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 28)
    }
}
