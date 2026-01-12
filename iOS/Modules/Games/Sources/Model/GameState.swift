//
//  GameState.swift
//  Games
//
//  Created by sungkug_apple_developer_ac on 1/12/26.
//

public struct GameState: Equatable, Sendable {
    public var character: CharacterState
    public var respawn: RespawnState
    
    // TODO: 상대편 캐릭터 상태 추가    
    public init(
        character: CharacterState = .init(),
        respawn: RespawnState = .init()
    ) {
        self.character = character
        self.respawn = respawn
    }
}
