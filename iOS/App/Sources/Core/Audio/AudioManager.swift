//
//  AudioManager.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 2/4/26.
//


import AVFoundation
import Foundation

final class AudioManager: AudioManaging {
    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [SFXAsset: AVAudioPlayer] = [:]
    private var bgmVolume: Float = 0.2
    private var sfxVolume: Float = 1.0

    private init() {}

    func playBGM(_ bgm: BGMAsset) {
        guard let player = makePlayer(name: bgm.filename, ext: bgm.fileExtension) else { return }
        player.numberOfLoops = -1
        player.volume = bgmVolume
        player.prepareToPlay()
        player.play()
        bgmPlayer = player
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    func playSFX(_ sfx: SFXAsset) {
        if let cached = sfxPlayers[sfx] {
            cached.currentTime = 0
            cached.volume = sfxVolume
            cached.play()
            return
        }

        guard let player = makePlayer(name: sfx.filename, ext: sfx.fileExtension) else { return }
        player.volume = sfxVolume
        player.prepareToPlay()
        player.play()
        sfxPlayers[sfx] = player
    }

    func setBGMVolume(_ value: Float) {
        bgmVolume = max(0, min(1, value))
        bgmPlayer?.volume = bgmVolume
    }

    func setSFXVolume(_ value: Float) {
        sfxVolume = max(0, min(1, value))
    }

    private func makePlayer(name: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }
}
