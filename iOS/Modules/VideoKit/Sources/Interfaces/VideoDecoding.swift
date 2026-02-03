//
//  VideoDecoding.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import AVFoundation

public protocol VideoDecoding: AnyObject {
    var output: ((CMSampleBuffer) -> Void)? { get set }
    func reset()
    func decode(data: Data)
}
