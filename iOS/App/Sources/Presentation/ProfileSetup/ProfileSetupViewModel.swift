//
//  ProfileSetupViewModel.swift
//  App
//
// Created by 영빈 on 1/7/26.
//

import Observation
import SwiftUI

// MARK: - Character Avatar

enum CharacterAvatar: CaseIterable, Equatable {
    case character1
    case character2
    case character3
    case character4
    case character5
    case character6
    
    var image: Image {
        switch self {
        case .character1: AppAsset.Image.character1.swiftUIImage
        case .character2: AppAsset.Image.character2.swiftUIImage
        case .character3: AppAsset.Image.character3.swiftUIImage
        case .character4: AppAsset.Image.character4.swiftUIImage
        case .character5: AppAsset.Image.character5.swiftUIImage
        case .character6: AppAsset.Image.character6.swiftUIImage
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class ProfileSetupViewModel {
    
    var nickname: String
    var selectedAvatar: CharacterAvatar
    
    let avatars: [CharacterAvatar] = CharacterAvatar.allCases
    
    init() {
        self.nickname = ""
        self.selectedAvatar = CharacterAvatar.allCases.randomElement() ?? .character1
    }
    
    func selectAvatar(_ avatar: CharacterAvatar) {
        selectedAvatar = avatar
    }
    
    // TODO: 랜덤 닉네임 생성 로직 적용
    // TODO: UserDefaults에 프로필 저장/복원
    
    func proceedToLobby() {
        // TODO: LobbyView로 이동
    }
}
