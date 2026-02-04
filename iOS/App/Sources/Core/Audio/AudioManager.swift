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
    private var bgmVolume: Float = 0.3
    private var sfxVolume: Float = 0.6
    private var bgmFadeTimer: Timer?
    private var currentBGM: BGMAsset?

    private init() {
        applyVolumeFromDefaults()
    }

    func playBGM(_ bgm: BGMAsset) {
        bgmFadeTimer?.invalidate()
        bgmFadeTimer = nil
        guard let player = makePlayer(name: bgm.filename, ext: bgm.fileExtension) else { return }
        player.numberOfLoops = -1
        player.volume = bgmVolume
        player.prepareToPlay()
        player.play()
        bgmPlayer = player
        currentBGM = bgm
    }

    func stopBGMIfPlaying(_ bgm: BGMAsset) {
        guard currentBGM == bgm else { return }
        fadeOutBGM()
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

    func applyVolumeFromDefaults() {
        let level = SettingsLevel(rawValue: UserDefaultsList.Settings.soundVolumeRaw) ?? .medium
        let volume: Float
        switch level {
        case .low:
            volume = 0.1
        case .medium:
            volume = 0.3
        case .high:
            volume = 0.6
        }
        setBGMVolume(volume)
        setSFXVolume(volume)
    }

    func fadeOutBGM(duration: TimeInterval = 0.4) {
        guard let player = bgmPlayer else { return }
        bgmFadeTimer?.invalidate()

        let steps = 12
        let interval = duration / Double(steps)
        let startVolume = player.volume
        var currentStep = 0
        let fadingPlayer = player

        bgmFadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            currentStep += 1
            let progress = min(Float(currentStep) / Float(steps), 1.0)
            fadingPlayer.volume = startVolume * (1.0 - progress)

            if currentStep >= steps {
                timer.invalidate()
                self.bgmFadeTimer = nil
                fadingPlayer.stop()
                if self.bgmPlayer === fadingPlayer {
                    self.bgmPlayer = nil
                    self.currentBGM = nil
                }
            }
        }
    }

    private func makePlayer(name: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }
}
