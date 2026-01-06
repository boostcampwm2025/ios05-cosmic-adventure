//
//  ProfileSetupViewModel.swift
//  App
//
// Created by 영빈 on 1/7/26.
//

import Observation

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
