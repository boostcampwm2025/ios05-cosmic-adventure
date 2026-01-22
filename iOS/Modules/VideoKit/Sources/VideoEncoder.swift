//
//  VideoEncoder.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import VideoToolbox
import QuartzCore

final public class VideoEncoder: VideoEncoding {

    private let configuration: VideoConfiguration
    private var session: VTCompressionSession?
    public var output: ((Data) -> Void)?
    private var isInvalidated = false
    private var retainedSelf: Unmanaged<VideoEncoder>?

    private static var encodingCallback: VTCompressionOutputCallback = { (refCon, _, status, flags, sampleBuffer) in
        guard status == noErr,
              let sampleBuffer = sampleBuffer,
              let refCon = refCon else {
            return
        }

        // encoder 인스턴스 복원
        let encoder = Unmanaged<VideoEncoder>.fromOpaque(refCon).takeUnretainedValue()

        // H264 NAL Unit 경계
        let startCode = Data([0, 0, 0, 1])

        var framePayload = Data()

        // NAL 유닛 헤더 길이를 담을 변수 (기본값 4로 설정하되 업데이트 예정)
        var nalHeaderLength: Int32 = 4

        // 1. SPS/PPS (포맷 정보 설명서) 추출
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
            var spsPtr: UnsafePointer<UInt8>?, spsSize = 0
            var ppsPtr: UnsafePointer<UInt8>?, ppsSize = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: 0,
                                                               parameterSetPointerOut: &spsPtr,
                                                               parameterSetSizeOut: &spsSize,
                                                               parameterSetCountOut: nil,
                                                               nalUnitHeaderLengthOut: &nalHeaderLength)
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                               parameterSetIndex: 1,
                                                               parameterSetPointerOut: &ppsPtr,
                                                               parameterSetSizeOut: &ppsSize,
                                                               parameterSetCountOut: nil,
                                                               nalUnitHeaderLengthOut: nil)

            if let sps = spsPtr,
               let pps = ppsPtr {
                framePayload.append(startCode)
                framePayload.append(Data(bytes: sps, count: spsSize))
                framePayload.append(startCode)
                framePayload.append(Data(bytes: pps, count: ppsSize))
            }
        }

        // 2. 실제 영상 데이터 추출
        if let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            if CMBlockBufferGetDataPointer(dataBuffer,
                                           atOffset: 0,
                                           lengthAtOffsetOut: nil,
                                           totalLengthOut: &length,
                                           dataPointerOut: &dataPointer) == kCMBlockBufferNoErr,
               let ptr = dataPointer {
                var offset = 0
                while offset < length {
                    var unitLen: UInt32 = 0

                    // nalHeaderLength에 따라 바이트를 읽고 변환
                    if nalHeaderLength == 4 {
                        memcpy(&unitLen, ptr + offset, 4)
                        unitLen = CFSwapInt32BigToHost(unitLen)
                    } else if nalHeaderLength == 2 {
                        var tempLen: UInt16 = 0
                        memcpy(&tempLen, ptr + offset, 2)
                        unitLen = UInt32(CFSwapInt16BigToHost(tempLen))
                    } else if nalHeaderLength == 1 {
                        unitLen = UInt32(UInt8(bitPattern: ptr[offset]))
                    }

                    framePayload.append(startCode)
                    framePayload.append(Data(bytes: ptr + offset + Int(nalHeaderLength), count: Int(unitLen)))

                    offset += Int(nalHeaderLength + Int32(unitLen))
                }
            }
        }

        if !framePayload.isEmpty {
            encoder.output?(framePayload)
        }
    }

    public init(configuration: VideoConfiguration = VideoConfiguration()) {
        self.configuration = configuration
        setupSession()
    }

    deinit {
        assert(isInvalidated || session == nil, "❌ VideoEncoder.invalidate()를 반드시 호출")
    }

    private func setupSession() {
        let retained = Unmanaged.passRetained(self)
        self.retainedSelf = retained

        let status = VTCompressionSessionCreate(
            allocator: nil,
            width: configuration.resolutionWidth,
            height: configuration.resolutionHeight,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: VideoEncoder.encodingCallback,
            refcon: UnsafeMutableRawPointer(retained.toOpaque()),
            compressionSessionOut: &session
        )

        guard status == noErr, let session = session else {
            retained.release()
            self.retainedSelf = nil
            return
        }

        // 실시간 저지연 설정
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)

        // kCFBooleanFalse를 설정하여 프레임 재정렬(B-Frame)을 허용하지 않음
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)

        // 2초마다 키프레임 (화면 깨짐 방어)
        let duration = configuration.keyFrameIntervalDuration // 2.0
        let frameInterval = Int32(Double(configuration.frameRate) * duration)

        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: configuration.frameRate as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: frameInterval as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: duration as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: configuration.highBitrate as CFNumber)

        VTCompressionSessionPrepareToEncodeFrames(session)
    }

    public func changeBitrate(to bitrate: Int) {
        guard let session = session else { return }
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate as CFNumber)
    }

    // 압축은 비동기 진행, 완료시 OS가 encodingCallback 호출
    public func encode(pixelBuffer: CVPixelBuffer) {
        guard let session = session else { return }
        let now = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000)
        VTCompressionSessionEncodeFrame(session,
                                        imageBuffer: pixelBuffer,
                                        presentationTimeStamp: now,
                                        duration: .invalid,
                                        frameProperties: nil,
                                        sourceFrameRefcon: nil,
                                        infoFlagsOut: nil)
    }

    public func invalidate() {
        guard !isInvalidated, let session = session else { return }
        isInvalidated = true

        // 대기 중인 프레임 처리 및 세션 중단
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(session)

        // setupSession에서 늘렸던 참조 카운트를 해제
        retainedSelf?.release()
        retainedSelf = nil

        self.session = nil
    }
}
