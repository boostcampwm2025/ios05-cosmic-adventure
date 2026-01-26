//
//  VideoDecoding.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import AVFoundation

public protocol VideoDecoding: AnyObject {
    var displayLayer: AVSampleBufferDisplayLayer? { get set }
    func decode(data: Data)
    func reset()
}
