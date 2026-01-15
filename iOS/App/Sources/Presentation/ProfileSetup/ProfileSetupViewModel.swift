//
//  ProfileSetupViewModel.swift
//  App
//
// Created by 영빈 on 1/7/26.
//

import Foundation
import Observation

import StorageKit

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
    
    func proceedToLobby(modelContext: ModelContext) {
        // TODO: 랜덤 닉네임 생성 로직 적용
        let finalNickname = nickname.isEmpty ? "건방진 탐험가123" : nickname
        
        let newPlayer = Player(
            id: UUID(),
            nickname: finalNickname,
            character: self.selectedAvatar.rawValue
        )
        
        modelContext.insert(newPlayer)
        
        // TODO: LobbyView로 이동
    }
}
