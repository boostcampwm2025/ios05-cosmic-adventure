//
//  DeterministicUUID.swift
//  NetworkKit
//
//  Created by sungkug_apple_developer_ac on 1/26/26.
//

import CryptoKit
import Foundation

public enum DeterministicUUID {
    public static func fromString(_ value: String, namespace: String) -> UUID {
        let data = Data((namespace + ":" + value).utf8)
        let hash = SHA256.hash(data: data)
        var bytes = Array(hash.prefix(16))
        // RFC 4122 variant + version 5 (namespace-based) style
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
