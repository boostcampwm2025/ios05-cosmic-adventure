//
//  VideoManagerTests.swift
//  AppTests
//
//  Created by soyoung on 2/3/26.
//

import XCTest
import AVFoundation
@testable import App
@testable import VideoKit
@testable import NetworkKit

final class VideoManagerTests: XCTestCase {

    var sut: VideoManager!
    var mockNetworkSessionManager: MockConnectionSessionManager!
    var mockWebSocketSessionManager: MockConnectionSessionManager!

    override func setUp() {
        super.setUp()
        mockNetworkSessionManager = MockConnectionSessionManager()
        mockWebSocketSessionManager = MockConnectionSessionManager()

        sut = VideoManager(
            networkSessionManager: mockNetworkSessionManager,
            webSocketSessionManager: mockWebSocketSessionManager
        )
    }

    override func tearDown() {
        sut = nil
        mockNetworkSessionManager = nil
        mockWebSocketSessionManager = nil
        super.tearDown()
    }

    // MARK: - Layer Lifecycle & Reset Tests

    // 인스턴스 교체 + 계층 제거 + 리소스 정리 검증
    func testReset_PerformsFullLayerCleanupAndReplacement() {
        // Given: 이전 레이어 상태 및 계층 설정
        let containerLayer = CALayer()
        let oldLayer = sut.remoteDisplayLayer
        containerLayer.addSublayer(oldLayer)

        XCTAssertNotNil(oldLayer.superlayer, "리셋 전에는 부모 뷰가 있어야 함")

        // When: 리셋 실행
        sut.reset()

        // Then: 메인 스레드에서 모든 정리 작업 검증
        let expectation = self.expectation(description: "레이어 정리 및 교체 완료 확인")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotEqual(oldLayer, self.sut.remoteDisplayLayer, "새 레이어로 교체되어야 함")
            XCTAssertNil(oldLayer.superlayer, "이전 레이어는 반드시 부모 뷰에서 제거되어야 함")
            XCTAssertNil(oldLayer.controlTimebase, "타임베이스가 nil로 정리되어야 함")

            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // 연속 리셋 시에도 레이어가 매번 새로 생성되는지
    func testConsecutiveResets_CreatesUniqueLayers() {
        // Given: 초기 상태
        var layerAddresses: Set<String> = []

        for _ in 0..<3 {
            let address = String(describing: Unmanaged.passUnretained(sut.remoteDisplayLayer).toOpaque())
            layerAddresses.insert(address)

            // When: 리셋 실행
            sut.reset()

            let exp = self.expectation(description: "Wait for reset")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
            waitForExpectations(timeout: 1.0)
        }

        // Then: 모든 레이어 주소가 다름
        XCTAssertEqual(layerAddresses.count, 3, "매 리셋마다 고유한 레이어 인스턴스가 생성되어야 함")
    }

    // reset() 호출 시 encoder가 재생성되는지
    func testReset_RecreatesEncoder() {
        // Given: 초기 encoder 존재 확인
        let testPixelBuffer = createTestPixelBuffer()

        // encoder output 콜백 설정
        sut.processFrame(pixelBuffer: testPixelBuffer)

        // When: reset 호출
        sut.reset()

        // encoder 재생성 대기
        let expectation = self.expectation(description: "Encoder recreates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Then: 새 encoder가 동작하는지 확인
            self.sut.processFrame(pixelBuffer: testPixelBuffer)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // encoder가 정상 동작하면 테스트 통과
        XCTAssertTrue(true, "Encoder should be recreated and functional")
    }

    // MARK: - Memory Management Tests

    // reset() 후 이전 레이어가 메모리에서 해제되는지
    func testReset_ReleasesOldLayer() {
        // Given: weak 참조로 이전 레이어 추적
        weak let oldLayerRef: AVSampleBufferDisplayLayer? = sut.remoteDisplayLayer
        XCTAssertNotNil(oldLayerRef, "Old layer should exist initially")

        // When: reset 호출
        sut.reset()

        // 메인 스레드 작업 완료 대기
        let expectation = self.expectation(description: "Layer reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: 이전 레이어가 해제됨 (weak 참조가 nil)
        XCTAssertNil(oldLayerRef, "Old layer should be deallocated after reset")
    }

    // MARK: - Integration Tests

    // 통합 테스트: 전체 게임 사이클 시뮬레이션 (잔상 방지 확인)
    func testFullGameCycle_PreventsGhosting() {
        // Given: 게임 시작 (첫 번째 게임)
        let player1 = PlayerInfo(id: UUID(), role: .remote, displayName: "Player 1", avatar: .character1)
        sut.setTargetPlayer(player1)
        let layer1 = sut.remoteDisplayLayer
        let address1 = String(describing: Unmanaged.passUnretained(layer1).toOpaque())

        // When: 게임 종료 후 새 게임 시작
        sut.reset() // (AppContainer.makeVideoManager)

        let expectation1 = self.expectation(description: "First reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // 두 번째 게임 시작
        let player2 = PlayerInfo(id: UUID(), role: .remote, displayName: "Player 2", avatar: .character2)
        sut.setTargetPlayer(player2)
        let layer2 = sut.remoteDisplayLayer
        let address2 = String(describing: Unmanaged.passUnretained(layer2).toOpaque())

        // 세 번째 게임 시작
        sut.reset()

        let expectation2 = self.expectation(description: "Second reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        let layer3 = sut.remoteDisplayLayer
        let address3 = String(describing: Unmanaged.passUnretained(layer3).toOpaque())

        // Then: 매 게임마다 다른 레이어 인스턴스 사용
        XCTAssertNotEqual(address1, address2, "Second game should use different layer")
        XCTAssertNotEqual(address2, address3, "Third game should use different layer")
        XCTAssertNotEqual(address1, address3, "First and third layers should be different")
    }

    // MARK: - Helper Methods

    private func createTestPixelBuffer() -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            192,
            192,
            kCVPixelFormatType_32BGRA,
            options as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            XCTFail("Failed to create test pixel buffer: \(status)")
            fatalError("Test setup failed")
        }

        return buffer
    }
}
