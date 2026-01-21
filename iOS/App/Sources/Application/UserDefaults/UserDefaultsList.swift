//
//  UserDefaultsList.swift
//  App
//
//  Created by 강윤서 on 1/8/26.
//

enum UserDefaultKeys: String {
    case isPermissionChecked
    case isGuideChecked
    
    // MARK: - Settings (SSOT)
    
    case jumpSensitivity
    case tiltSensitivity
    case soundVolume
    case isHapticsEnabled
    case facePreviewSize
}

public enum SettingsLevel: Int {
    case low = 0
    case medium = 1
    case high = 2
}

public protocol GameConfigProviding {
    var jumpSensitivity: SettingsLevel { get }
    var tiltSensitivity: SettingsLevel { get }
    var facePreviewSize: SettingsLevel { get }
}

public struct UserDefaultsList {
    public struct Permission {
        @UserDefaultWrapper<Bool>(key: UserDefaultKeys.isPermissionChecked.rawValue, defaultValue: false)
        public static var hasCompletedPermissionSetup
    }
    
    public struct Game {
        @UserDefaultWrapper<Bool>(key: UserDefaultKeys.isGuideChecked.rawValue, defaultValue: false)
        public static var isGuideChecked
    }
    
    public struct Settings: GameConfigProviding {
        @UserDefaultWrapper<Int>(key: UserDefaultKeys.jumpSensitivity.rawValue, defaultValue: SettingsLevel.medium.rawValue)
        public static var jumpSensitivityRaw
        
        @UserDefaultWrapper<Int>(key: UserDefaultKeys.tiltSensitivity.rawValue, defaultValue: SettingsLevel.medium.rawValue)
        public static var tiltSensitivityRaw
        
        @UserDefaultWrapper<Int>(key: UserDefaultKeys.soundVolume.rawValue, defaultValue: SettingsLevel.medium.rawValue)
        public static var soundVolumeRaw
        
        @UserDefaultWrapper<Bool>(key: UserDefaultKeys.isHapticsEnabled.rawValue, defaultValue: true)
        public static var isHapticsEnabled
        
        @UserDefaultWrapper<Int>(key: UserDefaultKeys.facePreviewSize.rawValue, defaultValue: SettingsLevel.medium.rawValue)
        public static var facePreviewSizeRaw
        
        public var jumpSensitivity: SettingsLevel {
            SettingsLevel(rawValue: Self.jumpSensitivityRaw) ?? .medium
        }
        
        public var tiltSensitivity: SettingsLevel {
            SettingsLevel(rawValue: Self.tiltSensitivityRaw) ?? .medium
        }
        
        public var facePreviewSize: SettingsLevel {
            SettingsLevel(rawValue: Self.facePreviewSizeRaw) ?? .medium
        }
    }
}
