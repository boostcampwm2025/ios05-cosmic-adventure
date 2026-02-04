//
//  AudioManaging.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 2/4/26.
//

import Foundation

protocol AudioManaging {
    func playBGM(_ bgm: BGMAsset)
    func stopBGMIfPlaying(_ bgm: BGMAsset)
    func playSFX(_ sfx: SFXAsset)
    func setBGMVolume(_ value: Float)
    func setSFXVolume(_ value: Float)
}

enum BGMAsset: String, CaseIterable {
    case lobby
    case gameplay

    var filename: String { rawValue }
    var fileExtension: String { "mp3" }
}

enum SFXAsset: String, CaseIterable {
    case jump
    case buttonTap

    var filename: String { rawValue }
    var fileExtension: String { "mp3" }
}
