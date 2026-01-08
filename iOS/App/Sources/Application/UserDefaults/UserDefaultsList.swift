//
//  UserDefaultsList.swift
//  App
//
//  Created by 강윤서 on 1/8/26.
//

enum UserDefaultKeys: String {
    case localNetworkPermission
    case cameraPermission
}

public struct UserDefaultsList {
    public struct Permission {
        @UserDefaultWrapper<Bool>(key: UserDefaultKeys.localNetworkPermission.rawValue) public static var localNetworkPermission
        @UserDefaultWrapper<Bool>(key: UserDefaultKeys.cameraPermission.rawValue) public static var cameraPermission
    }
}
