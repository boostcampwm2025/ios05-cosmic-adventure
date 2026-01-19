//
//  VideoEncoder.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import VideoToolbox
import QuartzCore

final public class VideoEncoder {
    
    private let configuration: VideoConfiguration
    private var session: VTCompressionSession?
    public  var output: ((Data) -> Void)?

    private static var encodingCallback: VTCompressionOutputCallback = { (
        refCon: UnsafeMutableRawPointer?,
        _: UnsafeMutableRawPointer?,
        status: OSStatus,
        _: VTEncodeInfoFlags,
        sampleBuffer: CMSampleBuffer?
    ) in
        guard status == noErr,
              let sampleBuffer = sampleBuffer,
              let refCon = refCon else {
            return
        }

        let encoder = Unmanaged<VideoEncoder>.fromOpaque(refCon).takeUnretainedValue()

        if let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?

            if CMBlockBufferGetDataPointer(
                dataBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &length,
                dataPointerOut: &dataPointer
            ) == kCMBlockBufferNoErr {
                if let pointer = dataPointer {
                    let data = Data(bytes: pointer, count: length)
                    encoder.output?(data)
                }
            }
        }
    }

    public init(configuration: VideoConfiguration = VideoConfiguration()) {
        self.configuration = configuration
        setupSession(initialBitrate: configuration.highBitrate)
    }

    deinit {
        if let session = session {
            // 대기 중인 프레임 종료
            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)

            // 세션 무효화, 콜백 X
            VTCompressionSessionInvalidate(session)
        }
    }

    private func setupSession(initialBitrate: Int) {
        VTCompressionSessionCreate(
            allocator: nil,
            width: configuration.width,
            height: configuration.height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: VideoEncoder.encodingCallback,
            refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            compressionSessionOut: &session
        )

        guard let session = session else { return }

        // 2초마다 키프레임 (화면깨짐 복구용)
        let duration = configuration.keyFrameIntervalDuration
        let frameInterval = Int32(Double(configuration.frameRate) * duration)

        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: frameInterval as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: duration as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: configuration.frameRate as CFNumber)

        changeBitrate(to: initialBitrate)
    }

    public func changeBitrate(to bps: Int) {
        guard let session = session else { return }
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bps as CFNumber)
    }

    // 압축은 비동기 진행, 완료시 OS가 encodingCallback 호출
    public func encode(pixelBuffer: CVPixelBuffer) {
        guard let session = session else { return }
        let now = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000)

        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: now,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }
}
