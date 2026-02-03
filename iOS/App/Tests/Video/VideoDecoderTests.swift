//
//  VideoDecoderTests.swift
//  AppTests
//
//  Created by soyoung on 2/3/26.
//

import XCTest
import AVFoundation
@testable import VideoKit

final class VideoDecoderTests: XCTestCase {

    var sut: VideoDecoder!

    override func setUp() {
        super.setUp()
        sut = VideoDecoder()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // 디코딩 완료 콜백이 오는지
    func testDecode_OutputsSampleBufferViaCallback() {
        let expectation = self.expectation(description: "디코딩 완료 콜백 대기")
        var receivedBuffer: CMSampleBuffer?

        sut.output = { buffer in
            receivedBuffer = buffer
            expectation.fulfill()
        }

        // SPS + PPS + IDR 프레임이 모두 포함된 유효 데이터 주입
        let testData = createTestH264Data()
        sut.decode(data: testData)

        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(receivedBuffer)
    }

    // 리셋 후 정상데이터 디코딩 콜백이 오는지
    func testReset_ClearsInternalState() {
        // Given: 쓰레기 데이터 주입
        sut.decode(data: Data([0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF]))

        // When: 리셋 실행
        sut.reset()

        // Then: 정상 데이터를 넣었을 때 콜백이 오는지 확인
        let expectation = self.expectation(description: "정상 데이터가 디코딩되어야 함")
        sut.output = { _ in
            expectation.fulfill()
        }

        sut.decode(data: createTestH264Data())
        waitForExpectations(timeout: 2.0)
    }

    private func createTestH264Data() -> Data {
        let sc: [UInt8] = [0, 0, 0, 1]
        // SPS
        let sps: [UInt8] = sc + [0x67, 0x42, 0x00, 0x0A, 0xF8, 0x41, 0xA2]
        // PPS
        let pps: [UInt8] = sc + [0x68, 0xCE, 0x38, 0x80]
        // IDR Frame
        let idr: [UInt8] = sc + [0x65, 0x00, 0x00, 0x00, 0x01, 0x00]
        // 종결자 (마지막 유닛 파싱을 강제하기 위함)
        let end: [UInt8] = sc

        return Data(sps + pps + idr + end)
    }
}
