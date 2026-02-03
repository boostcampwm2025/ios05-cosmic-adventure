//
//  LengthPrefixFramer.swift
//  NetworkKit
//
//  Created by 강윤서 on 2/1/26.
//

import Foundation
import Network
import os

final class LengthPrefixFramer: NWProtocolFramerImplementation {
    
    // MARK: - Properties
    
    static let definition = NWProtocolFramer.Definition(implementation: LengthPrefixFramer.self)
    static let label = "LengthPrefix"
    private static let headerSize = 4 // UInt32 빅엔디안
    private static let maxMessageSize = Int(UInt32.max)
    
    private let logger = Logger(subsystem: "com.cosmicadventure.networkkit", category: "LengthPrefixFramer")
    
    // MARK: - Initialization
    
    required init(framer: NWProtocolFramer.Instance) {}
    
    // MARK: - Methods
    
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        .ready
    }
    
    func stop(framer: NWProtocolFramer.Instance) -> Bool {
        true
    }
    
    func wakeup(framer: NWProtocolFramer.Instance) {}
    
    func cleanup(framer: NWProtocolFramer.Instance) {}
    
    // MARK: - Output (Send)
    
    func handleOutput(
        framer: NWProtocolFramer.Instance,
        message: NWProtocolFramer.Message,
        messageLength: Int,
        isComplete: Bool
    ) {
        // 4바이트 빅엔디안 길이 헤더 작성
        guard messageLength <= Self.maxMessageSize else {
            logger.error("메시지 길이가 UInt32 범위를 초과함: \(messageLength)")
            return
        }
        
        var length = UInt32(messageLength).bigEndian
        let headerData = Data(bytes: &length, count: Self.headerSize)
        framer.writeOutput(data: headerData)
        
        // 메시지 본문을 zero-copy로 전달
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        } catch {
            logger.error("프레이머 출력 쓰기 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input (Receive)
    
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            // 1) 4바이트 길이 헤더 파싱
            var messageLength: UInt32 = 0
            
            let headerParsed = framer.parseInput(
                minimumIncompleteLength: Self.headerSize,
                maximumLength: Self.headerSize
            ) { buffer, _ in
                guard let buffer, buffer.count >= Self.headerSize else { return 0 }
                messageLength = buffer.loadUnaligned(as: UInt32.self).bigEndian
                return Self.headerSize
            }
            
            
            guard headerParsed, messageLength > 0 else { break }
            guard messageLength <= Self.maxMessageSize else {
                logger.error("메시지 길이 제한 초과: \(messageLength)")
                return 0
            }
            
            // 2) 메시지 본문 파싱 및 전달
            let bodyParsed = framer.parseInput(
                minimumIncompleteLength: Int(messageLength),
                maximumLength: Int(messageLength)
            ) { buffer, _ in
                guard let buffer, buffer.count >= Int(messageLength) else { return 0 }
                /// 메세지 객체 생성
                let message = NWProtocolFramer.Message(definition: LengthPrefixFramer.definition)
                
                /// body와 message 전달
                framer.deliverInput(
                    data: Data(buffer.prefix(Int(messageLength))),
                    message: message,
                    isComplete: true
                )
                return Int(messageLength)
            }

            guard bodyParsed else { break }
        }

        return 0
    }
}
