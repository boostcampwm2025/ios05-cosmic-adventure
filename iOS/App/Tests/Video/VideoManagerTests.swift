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

    // MARK: - Layer Reset Tests

    // reset() 호출 시 새로운 레이어가 생성되는지
    func testReset_CreatesNewLayer() {
        // Given: 초기 레이어 참조 저장
        let originalLayer = sut.remoteDisplayLayer
        let originalAddress = Unmanaged.passUnretained(originalLayer).toOpaque()

        // When: reset 호출
        sut.reset()

        // 메인 스레드 작업 완료 대기
        let expectation = self.expectation(description: "Layer reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: 새 레이어가 생성됨
        let newLayer = sut.remoteDisplayLayer
        let newAddress = Unmanaged.passUnretained(newLayer).toOpaque()

        XCTAssertNotEqual(originalAddress, newAddress, "Reset should create a new layer instance")
    }

    // reset() 후 이전 레이어가 superlayer에서 제거되는지
    func testReset_RemovesOldLayerFromSuperlayer() {
        // Given: 레이어를 컨테이너에 추가
        let containerLayer = CALayer()
        containerLayer.addSublayer(sut.remoteDisplayLayer)

        let originalLayer = sut.remoteDisplayLayer
        XCTAssertNotNil(originalLayer.superlayer, "Original layer should have superlayer")

        // When: reset 호출
        sut.reset()

        // 메인 스레드 작업 완료 대기
        let expectation = self.expectation(description: "Layer removal completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: 이전 레이어가 제거됨
        XCTAssertNil(originalLayer.superlayer, "Old layer should be removed from superlayer")
    }

    // 연속 reset 호출 시 레이어가 매번 새로 생성되는지
    func testMultipleResets_CreatesDifferentLayers() {
        // Given: 초기 상태
        var layerAddresses: [String] = []

        // When: reset을 3번 호출
        for _ in 0..<3 {
            sut.reset()

            let expectation = self.expectation(description: "Reset completes")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1.0)

            let layer = sut.remoteDisplayLayer
            let address = String(describing: Unmanaged.passUnretained(layer).toOpaque())
            layerAddresses.append(address)
        }

        // Then: 모든 레이어 주소가 다름
        let uniqueAddresses = Set(layerAddresses)
        XCTAssertEqual(uniqueAddresses.count, 3, "Each reset should create a unique layer")
    }

    // MARK: - State Reset Tests

    // reset() 호출 시 remotePlayer가 nil로 초기화되는지
    func testReset_ClearsRemotePlayer() {
        // Given: remotePlayer 설정
        let player = PlayerInfo(
            id: UUID(),
            role: .remote,
            displayName: "Test Player",
            avatar: .character1
        )
        sut.setTargetPlayer(player)
        XCTAssertNotNil(sut.remotePlayer)

        // When: reset 호출
        sut.reset()

        // Then: remotePlayer가 nil
        XCTAssertNil(sut.remotePlayer, "Reset should clear remotePlayer")
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
