//
//  VideoEncoding.swift
//  VideoKit
//
//  Created by soyoung on 1/19/26.
//

import VideoToolbox

public protocol VideoEncoding: AnyObject {
    var output: ((Data) -> Void)? { get set }
    func encode(pixelBuffer: CVPixelBuffer)
    func changeBitrate(to bps: Int)
    func invalidate()
}
