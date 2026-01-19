//
//  CharacterAvatar.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

enum CharacterAvatar: String, Codable, CaseIterable, Equatable {
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
    
    var name: String {
        switch self {
        case .character1: AppAsset.Image.character1.name
        case .character2: AppAsset.Image.character2.name
        case .character3: AppAsset.Image.character3.name
        case .character4: AppAsset.Image.character4.name
        case .character5: AppAsset.Image.character5.name
        case .character6: AppAsset.Image.character6.name
        }
    }
}
