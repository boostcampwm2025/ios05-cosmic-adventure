//
//  FaceTrackingManager.swift
//  iOS
//
//  Created by soyoung on 12/16/25.
//

import ARKit
import VideoToolbox // 이미지 변환을 위해 필요

@Observable
class FaceTrackingManager: NSObject, ObservableObject, ARSessionDelegate {
    var jawOpenValue: Float = 0.0
    var mouthFunnelValue: Float = 0.0
    var mouthPuckerValue: Float = 0.0
    var mouthCloseValue: Float = 0.0
    var cheekPuffValue: Float = 0.0
    var headRoll: Float = 0.0
    // 이미지가 준비되면 실행할 행동 (클로저)
    var onImageCaptured: ((Data) -> Void)?

    // 프레임 스킵용 카운터 (너무 많이 보내면 끊기니까 3번에 1번만 전송)
    private var frameCounter = 0

    var session = ARSession()

    override init() {
        super.init()
        setupSession()
    }

    func setupSession() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        session.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }

        // 값 추출
        let jawOpen = faceAnchor.blendShapes[.jawOpen]?.floatValue ?? 0.0
        let funnel = faceAnchor.blendShapes[.mouthFunnel]?.floatValue ?? 0.0
        let pucker = faceAnchor.blendShapes[.mouthPucker]?.floatValue ?? 0.0
        let close = faceAnchor.blendShapes[.mouthClose]?.floatValue ?? 0.0
        let puff = faceAnchor.blendShapes[.cheekPuff]?.floatValue ?? 0.0
        let roll = faceAnchor.transform.eulerAngles.z

        Task { @MainActor in
            self.jawOpenValue = jawOpen
            self.mouthFunnelValue = funnel
            self.mouthPuckerValue = pucker
            self.mouthCloseValue = close
            self.cheekPuffValue = puff
            self.headRoll = -roll
        }
    }

    // 매 프레임마다 카메라 화면을 가져오는 함수
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 1. 프레임 스킵 (60fps -> 20fps로 낮춤)
        frameCounter += 1
        if frameCounter % 3 != 0 { return }

        // 2. CVPixelBuffer(raw 데이터)를 UIImage로 변환
        let pixelBuffer = frame.capturedImage
        if let imageData = convertToJPEG(pixelBuffer: pixelBuffer) {
            // 3. 변환된 JPEG 데이터를 밖으로 내보냄 (ContentView에서 받아서 전송할 것임)
            Task { @MainActor in
                self.onImageCaptured?(imageData)
            }
        }
    }

    // 픽셀 버퍼를 JPEG 데이터로 변환하는 헬퍼 함수
    private func convertToJPEG(pixelBuffer: CVPixelBuffer) -> Data? {
        var cgImage: CGImage?
        // 1. CVPixelBuffer -> CGImage 변환
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else { return nil }

        // 2. 오리엔테이션 맞춰서 UIImage 생성 (아직은 원본 크기)
        let sourceImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)

        // 3. 이미지 크기 줄이기 (Downscaling) 
        // 목표 크기: 가로 200px (비율 유지) -> 데이터 크기가 1/20로 줄어듦!
        let targetWidth: CGFloat = 200.0
        let scaleFactor = targetWidth / sourceImage.size.width
        let targetHeight = sourceImage.size.height * scaleFactor
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        // 그래픽 컨텍스트를 열어서 작게 다시 그림
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        // 4. 압축해서 내보내기 (화질 0.5 정도면 충분)
        let jpegData = resizedImage.jpegData(compressionQuality: 0.5)

        // 용량 측정 로그 찍기
//        if let data = jpegData {
//            let bytes = Double(data.count)
//            let kb = bytes / 1024.0
//            print("📦 전송 데이터 크기: \(Int(bytes)) bytes (약 \(String(format: "%.2f", kb)) KB)") // (약 17.14 KB)
//        }

        return jpegData
    }
}

extension simd_float4x4 {
    var eulerAngles: SIMD3<Float> {
        return SIMD3<Float>(
            asin(-columns.2.y),
            atan2(columns.2.x, columns.2.z),
            atan2(columns.0.y, columns.1.y)
        )
    }
}
