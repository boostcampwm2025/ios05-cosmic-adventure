//
//  Player.swift
//  StorageKit
//
//  Created by 강윤서 on 1/13/26.
//

import Foundation
@_exported import SwiftData

@Model
public class Player {
    @Attribute(.unique)
    public var id: UUID
    
    public var nickname: String
    public var character: String
    
    public init(
        id: UUID,
        nickname: String,
        character: String
    ) {
        self.id = id
        self.nickname = nickname
        self.character = character
    }
}
