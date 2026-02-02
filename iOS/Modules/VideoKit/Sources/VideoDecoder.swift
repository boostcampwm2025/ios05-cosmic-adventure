//
//  VideoDecoder.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import AVFoundation
import VideoToolbox
import os

final public class VideoDecoder: VideoDecoding {

    private var formatDescription: CMVideoFormatDescription?
    public var displayLayer: AVSampleBufferDisplayLayer?

    private var lastSps: Data?
    private var lastPps: Data?

    private let decodeQueue = DispatchQueue(label: "com.cosmicadventure.videokit.decoder")
    private var packetAccumulator = Data()

    private let logger = Logger(subsystem: "com.cosmicadventure.videokit", category: "VideoDecoder")

    public init() { }

    public func reset() {
        decodeQueue.async { [weak self] in
            self?.packetAccumulator.removeAll()
            self?.formatDescription = nil
            self?.lastSps = nil
            self?.lastPps = nil

            DispatchQueue.main.async { [weak self] in
                guard let layer = self?.displayLayer else { return }

                if #available(iOS 18.0, *) {
                    layer.sampleBufferRenderer.flush()
                    layer.sampleBufferRenderer.stopRequestingMediaData()
                } else {
                    layer.flushAndRemoveImage()
                    layer.stopRequestingMediaData()
                }
                
                layer.controlTimebase = nil
                layer.setNeedsDisplay()
            }
        }
    }

    // 외부에서 받은 H.264 데이터를 디코딩하여 화면에 그림
    public func decode(data: Data) {
        // 들어오는 모든 데이터를 직렬 큐에 넣어서 순차적으로 처리
        decodeQueue.async { [weak self] in
            self?.performDecode(data: data)
        }
    }

    private func performDecode(data: Data) {
        packetAccumulator.append(data)
        let startCode = Data([0, 0, 0, 1])

        while true {
            // 시작 코드 찾기
            guard let firstRange = packetAccumulator.range(of: startCode) else {
                // 시작 코드가 없으면 마지막 3바이트만 남김 (분할된 startCode 대비)
                if packetAccumulator.count > 4 {
                    packetAccumulator.removeSubrange(0..<packetAccumulator.count-3)
                }
                break
            }

            // 앞의 불필요한 데이터 제거
            if firstRange.lowerBound > 0 {
                packetAccumulator.removeSubrange(0..<firstRange.lowerBound)
                continue
            }

            // 다음 NAL Unit 찾기
            if let nextRange = packetAccumulator.range(
                of: startCode, options: [], in: 4..<packetAccumulator.count) {

                let unit = packetAccumulator.subdata(in: 4..<nextRange.lowerBound)
                handleNALUnit(unit)
                packetAccumulator.removeSubrange(0..<nextRange.lowerBound)
            } else {
                break  // 다음 NAL Unit이 아직 안 왔으면 대기
            }
        }
    }

    private func handleNALUnit(_ unit: Data) {
        guard unit.count > 0 else { return }
        let type = unit[0] & 0x1F // 바이너리의 하위 5비트 = NAL Unit 타입

        if type == 7 { // SPS (Sequence Parameter Set)
            if lastSps != unit {
                lastSps = unit
                formatDescription = nil
                logger.debug("[Decoder] 새로운 SPS 감지, 설명서 재생성 예약")
            }
        } else if type == 8 { // PPS (Picture Parameter Set)
            if lastPps != unit {
                lastPps = unit
                formatDescription = nil
                logger.debug("[Decoder] 새로운 PPS 감지, 설명서 재생성 예약")
            }
        } else if type == 1 || type == 5 {
            // 프레임 데이터
            // type == 5: I-Frame (키프레임, 독립적)
            // type == 1: P-Frame (이전 프레임 참조)
            guard let displayLayer = displayLayer else { return }

            if let sps = lastSps,
               let pps = lastPps {
                if formatDescription == nil {
                    updateFormatDescription(sps: sps, pps: pps)
                    logger.debug("[Decoder] 설명서 생성 성공! 영상 렌더링 준비 완료")
                }

                guard let formatDesc = formatDescription else { return }

                // 영상 데이터를 CMBlockBuffer로 변환
                var videoSlices = Data()
                var len = UInt32(unit.count).bigEndian
                videoSlices.append(Data(bytes: &len, count: 4))
                videoSlices.append(unit)

                if let blockBuffer = createBlockBuffer(from: videoSlices),
                   let sampleBuffer = createSampleBuffer(from: blockBuffer, format: formatDesc) {
                    enqueue(sampleBuffer, to: displayLayer)
                }
            }
        }
    }

    // Decoder 설명서 등록
    private func updateFormatDescription(sps: Data, pps: Data) {
        sps.withUnsafeBytes { spsIn in
            pps.withUnsafeBytes { ppsIn in
                let parameterSetPointers = [
                    spsIn.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    ppsIn.baseAddress!.assumingMemoryBound(to: UInt8.self)
                ]
                let parameterSetSizes = [sps.count, pps.count]
                CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                                                                    parameterSetCount: 2,
                                                                    parameterSetPointers: parameterSetPointers,
                                                                    parameterSetSizes: parameterSetSizes,
                                                                    nalUnitHeaderLength: 4, // startCode 크기
                                                                    formatDescriptionOut: &formatDescription)
            }
        }
    }

    private func createBlockBuffer(from data: Data) -> CMBlockBuffer? {
        var blockBuffer: CMBlockBuffer?
        let length = data.count

        // 메모리 블록 생성
        let status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: length,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: length,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        // 데이터 복사
        if status == noErr, let buffer = blockBuffer {
            let copyStatus = data.withUnsafeBytes { ptr in
                CMBlockBufferReplaceDataBytes(
                    with: ptr.baseAddress!,
                    blockBuffer: buffer,
                    offsetIntoDestination: 0,
                    dataLength: length
                )
            }
            guard copyStatus == kCMBlockBufferNoErr else {
                return nil
            }

            return buffer
        }
        return nil
    }

    private func createSampleBuffer(from blockBuffer: CMBlockBuffer, format: CMVideoFormatDescription) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?

        // 타이밍 정보 생성 (현재 시간 기준)
        // 타임스탬프를 .invalid로 설정 → 레이어가 즉시 렌더링
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: .invalid,
            decodeTimeStamp: .invalid
        )

        // 샘플 크기 정보
        var sampleSize = CMBlockBufferGetDataLength(blockBuffer)

        let status = withUnsafePointer(to: &timingInfo) { timingPtr in
            CMSampleBufferCreate(
                allocator: kCFAllocatorDefault,
                dataBuffer: blockBuffer,
                dataReady: true,
                makeDataReadyCallback: nil,
                refcon: nil,
                formatDescription: format,
                sampleCount: 1,
                sampleTimingEntryCount: 1,
                sampleTimingArray: timingPtr,
                sampleSizeEntryCount: 1,
                sampleSizeArray: &sampleSize,
                sampleBufferOut: &sampleBuffer
            )
        }

        if status == noErr, let buffer = sampleBuffer {
            let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer,
                                                                      createIfNecessary: true)
            if let dictArray = attachments as? [CFMutableDictionary],
               let first = dictArray.first {

                // '지금 당장 보여줘' 플래그
                CFDictionarySetValue(first,
                                     Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                     Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())

                // 이전 프레임을 덮어씌우기
                let endsPreviousSampleDuration = kCMSampleBufferAttachmentKey_EndsPreviousSampleDuration
                CFDictionarySetValue(first,
                                     Unmanaged.passUnretained(endsPreviousSampleDuration).toOpaque(),
                                     Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
            }
            return buffer
        }
        return nil
    }

    private func enqueue(_ sampleBuffer: CMSampleBuffer, to layer: AVSampleBufferDisplayLayer) {
        DispatchQueue.main.async {
            // 레이어가 view hierarchy에 있는지 확인
            guard layer.superlayer != nil else { return }

            let currentStatus: AVQueuedSampleBufferRenderingStatus
            if #available(iOS 18.0, *) {
                currentStatus = layer.sampleBufferRenderer.status
            } else {
                currentStatus = layer.status
            }

            // Failed 상태 복구
            if currentStatus == .failed {
                if #available(iOS 18.0, *) {
                    layer.sampleBufferRenderer.flush()
                } else {
                    layer.flush()
                }

                var tb: CMTimebase?
                CMTimebaseCreateWithSourceClock(allocator: nil,
                                                sourceClock: CMClockGetHostTimeClock(),
                                                timebaseOut: &tb)
                layer.controlTimebase = tb
                if let timebase = tb {
                    CMTimebaseSetRate(timebase, rate: 1.0)
                }
            }

            // Timebase 설정
            if layer.controlTimebase == nil {
                var tb: CMTimebase?
                CMTimebaseCreateWithSourceClock(allocator: nil,
                                                sourceClock: CMClockGetHostTimeClock(),
                                                timebaseOut: &tb)
                layer.controlTimebase = tb

            }
            
            // 시계가 정상 속도(1.0)로 흐름
            if let timebase = layer.controlTimebase {
                CMTimebaseSetRate(timebase, rate: 1.0)
            }

            // 샘플 버퍼 투입
            if #available(iOS 18.0, *) {
                layer.sampleBufferRenderer.enqueue(sampleBuffer)
            } else {
                layer.enqueue(sampleBuffer)
            }
        }
    }
}
