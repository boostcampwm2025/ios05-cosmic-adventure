//
//  VideoDecoder.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import AVFoundation
import VideoToolbox

final public class VideoDecoder {

    private let configuration: VideoConfiguration
    private var session: VTDecompressionSession?
    private var formatDescription: CMVideoFormatDescription?
    public weak var displayLayer: AVSampleBufferDisplayLayer?

    public init(configuration: VideoConfiguration = VideoConfiguration()) {
        self.configuration = configuration
    }

    // 외부에서 받은 H.264 데이터를 디코딩하여 화면에 그림
    public func decode(data: Data) {
        guard let displayLayer = displayLayer else { return }

        // Data -> CMBlockBuffer 메모리 블록으로 변환
        guard let blockBuffer = createBlockBuffer(from: data) else { return }

        // CMSampleBuffer 생성
        if let sampleBuffer = createSampleBuffer(from: blockBuffer) {
            enqueue(sampleBuffer, to: displayLayer)
        }
    }

    // MARK: - Private Helper Methods

    private func enqueue(_ sampleBuffer: CMSampleBuffer, to layer: AVSampleBufferDisplayLayer) {
        if #available(iOS 18.0, *) {
            if layer.sampleBufferRenderer.status == .failed {
                layer.sampleBufferRenderer.flush()
            }
            layer.sampleBufferRenderer.enqueue(sampleBuffer)
        } else {
            if layer.status == .failed {
                layer.flush()
            }
            layer.enqueue(sampleBuffer)
        }
    }

    private func createBlockBuffer(from data: Data) -> CMBlockBuffer? {
        let length = data.count
        var blockBuffer: CMBlockBuffer?

        // 메모리 블록 생성
        let status = data.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) -> OSStatus in
            if bufferPointer.baseAddress == nil { return -1 }

            return CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: nil,
                blockLength: length,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: length,
                flags: kCMBlockBufferAssureMemoryNowFlag,
                blockBufferOut: &blockBuffer
            )
        }

        guard status == kCMBlockBufferNoErr, let buffer = blockBuffer else { return nil }

        // 데이터 복사
        data.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) in
            guard let baseAddress = bufferPointer.baseAddress else { return }
            CMBlockBufferReplaceDataBytes(
                with: baseAddress,
                blockBuffer: buffer,
                offsetIntoDestination: 0,
                dataLength: length
            )
        }

        return blockBuffer
    }

    private func createSampleBuffer(from blockBuffer: CMBlockBuffer) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?

        // 타이밍 정보 생성 (현재 시간 기준)
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000),
            decodeTimeStamp: .invalid
        )

        // 샘플 크기 정보
        var sampleSize = CMBlockBufferGetDataLength(blockBuffer)

        // 규격 설정 H.264
        if formatDescription == nil {
            CMVideoFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                codecType: kCMVideoCodecType_H264,
                width: configuration.width,
                height: configuration.height,
                extensions: nil,
                formatDescriptionOut: &formatDescription
            )
        }

        guard let formatDescription = formatDescription else { return nil }

        // 데이터 + 시간 + 규격
        let status = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSize,
            sampleBufferOut: &sampleBuffer
        )

        return status == noErr ? sampleBuffer : nil
    }
}
