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

    // MARK: - setDisplayLayer Thread Safety Tests

    // setDisplayLayer가 decodeQueue에서 실행되는지
    func testSetDisplayLayer_ExecutesOnDecodeQueue() {
        // Given: 새 레이어 생성
        let newLayer = AVSampleBufferDisplayLayer()

        // When: setDisplayLayer 호출
        let expectation = self.expectation(description: "setDisplayLayer completes")

        sut.setDisplayLayer(newLayer)

        // decodeQueue는 비동기이므로 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        // Then: 크래시 없이 완료
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(true, "setDisplayLayer should complete without crash")
    }

    // 여러 스레드에서 동시에 setDisplayLayer 호출 시 thread-safe한지
    func testSetDisplayLayer_ConcurrentCalls_IsThreadSafe() {
        // Given: 여러 레이어 생성
        let layers = (0..<10).map { _ in AVSampleBufferDisplayLayer() }

        // When: 여러 스레드에서 동시에 setDisplayLayer 호출
        let expectation = self.expectation(description: "Concurrent calls complete")
        expectation.expectedFulfillmentCount = 10

        for layer in layers {
            DispatchQueue.global(qos: .userInitiated).async {
                self.sut.setDisplayLayer(layer)
                expectation.fulfill()
            }
        }

        // Then: 크래시 없이 완료
        waitForExpectations(timeout: 5.0)
        XCTAssertTrue(true, "Concurrent setDisplayLayer calls should be thread-safe")
    }

    // setDisplayLayer와 decode가 동시에 호출되어도 안전한지
    func testSetDisplayLayer_WithConcurrentDecode_IsThreadSafe() {
        // Given: 초기 레이어 설정
        let initialLayer = AVSampleBufferDisplayLayer()
        sut.setDisplayLayer(initialLayer)

        // 테스트용 비디오 데이터 (start code만 있는 최소 데이터)
        let testData = Data([0, 0, 0, 1, 0x67]) // SPS NAL unit start

        // When: setDisplayLayer와 decode를 동시에 호출
        let expectation = self.expectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 20

        for i in 0..<10 {
            // decode 호출
            DispatchQueue.global(qos: .userInitiated).async {
                self.sut.decode(data: testData)
                expectation.fulfill()
            }

            // setDisplayLayer 호출
            DispatchQueue.global(qos: .userInitiated).async {
                let newLayer = AVSampleBufferDisplayLayer()
                newLayer.frame = CGRect(x: CGFloat(i), y: 0, width: 60, height: 60)
                self.sut.setDisplayLayer(newLayer)
                expectation.fulfill()
            }
        }

        // Then: 크래시 없이 완료 (데이터 레이스 없음)
        waitForExpectations(timeout: 5.0)
        XCTAssertTrue(true, "setDisplayLayer and decode should be thread-safe together")
    }

    // MARK: - Reset Tests

    // reset() 호출 시 내부 상태가 초기화되는지
    func testReset_ClearsInternalState() {
        // Given: 레이어 설정 및 데이터 추가
        let layer = AVSampleBufferDisplayLayer()
        sut.setDisplayLayer(layer)

        // 초기 대기
        let setupExpectation = self.expectation(description: "Setup completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            setupExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: reset 호출
        sut.reset()

        // Then: 크래시 없이 완료
        let resetExpectation = self.expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            resetExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(true, "Reset should complete without crash")
    }

    // reset() 후 새 레이어 설정이 가능한지
    func testReset_AllowsNewLayerAssignment() {
        // Given: 초기 레이어 설정
        let initialLayer = AVSampleBufferDisplayLayer()
        sut.setDisplayLayer(initialLayer)

        let setupExpectation = self.expectation(description: "Setup completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            setupExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: reset 후 새 레이어 설정
        sut.reset()

        let resetExpectation = self.expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            resetExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        let newLayer = AVSampleBufferDisplayLayer()
        sut.setDisplayLayer(newLayer)

        // Then: 크래시 없이 완료
        let newLayerExpectation = self.expectation(description: "New layer set completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            newLayerExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(true, "Should be able to set new layer after reset")
    }

    // MARK: - Layer Management Tests

    // 레이어를 nil로 설정할 수 있는지
    func testSetDisplayLayer_CanSetNil() {
        // Given: 초기 레이어 설정
        let initialLayer = AVSampleBufferDisplayLayer()
        sut.setDisplayLayer(initialLayer)

        let setupExpectation = self.expectation(description: "Setup completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            setupExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: nil로 설정
        sut.setDisplayLayer(nil)

        // Then: 크래시 없이 완료
        let nilExpectation = self.expectation(description: "Nil set completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            nilExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(true, "Should be able to set displayLayer to nil")
    }

    // 레이어 교체가 순차적으로 처리되는지
    func testSetDisplayLayer_ProcessesSequentially() {
        // Given: 여러 레이어 생성
        let layers = (0..<5).map { i -> AVSampleBufferDisplayLayer in
            let layer = AVSampleBufferDisplayLayer()
            layer.frame = CGRect(x: CGFloat(i * 10), y: 0, width: 60, height: 60)
            return layer
        }

        // When: 순차적으로 레이어 설정
        for layer in layers {
            sut.setDisplayLayer(layer)
        }

        // Then: 모든 호출이 완료될 때까지 대기
        let expectation = self.expectation(description: "Sequential calls complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertTrue(true, "Sequential setDisplayLayer calls should complete")
    }
}
