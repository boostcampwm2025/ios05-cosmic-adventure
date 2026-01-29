//
//  SettingsViewModel.swift
//  App
//
//  Created by 영빈 on 1/21/26.
//

import Foundation
import Observation
import os

import StorageKit

@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.cosmicadventure.app", category: "SettingsViewModel")
    
    var nickname: String
    var selectedAvatar: CharacterAvatar
    let avatars: [CharacterAvatar] = CharacterAvatar.allCases
    
    var jumpSensitivity: Int {
        didSet { UserDefaultsList.Settings.jumpSensitivityRaw = jumpSensitivity }
    }
    
    var tiltSensitivity: Int {
        didSet { UserDefaultsList.Settings.tiltSensitivityRaw = tiltSensitivity }
    }
    
    var soundVolume: Int {
        didSet { UserDefaultsList.Settings.soundVolumeRaw = soundVolume }
    }
    
    var isHapticsEnabled: Bool {
        didSet { UserDefaultsList.Settings.isHapticsEnabled = isHapticsEnabled }
    }
    
    var facePreviewSize: Int {
        didSet { UserDefaultsList.Settings.facePreviewSizeRaw = facePreviewSize }
    }
    
    private let player: Player
    
    // MARK: - Init
    
    init(player: Player) {
        self.player = player
        self.nickname = player.nickname
        self.selectedAvatar = CharacterAvatar(rawValue: player.character) ?? .character1
        
        self.jumpSensitivity = UserDefaultsList.Settings.jumpSensitivityRaw
        self.tiltSensitivity = UserDefaultsList.Settings.tiltSensitivityRaw
        self.soundVolume = UserDefaultsList.Settings.soundVolumeRaw
        self.isHapticsEnabled = UserDefaultsList.Settings.isHapticsEnabled
        self.facePreviewSize = UserDefaultsList.Settings.facePreviewSizeRaw
    }
    
    func selectAvatar(_ avatar: CharacterAvatar) {
        selectedAvatar = avatar
    }
    
    func saveProfile(modelContext: ModelContext) {
        player.nickname = nickname.isEmpty ? player.nickname : nickname
        player.character = selectedAvatar.rawValue
        
        do {
            try modelContext.save()
        } catch {
            logger.error("[SettingsViewModel] 플레이어 정보 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }
}

#if DEBUG
extension SettingsViewModel {
    static func forPreview() -> SettingsViewModel {
        SettingsViewModel(
            player: Player(id: UUID(), nickname: "테스트 유저", character: "character1")
        )
    }
}
#endif
