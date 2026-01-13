//
//  UserDefaultsList.swift
//  App
//
//  Created by 강윤서 on 1/8/26.
//

enum UserDefaultKeys: String {
    case isPermissionChecked
}

public struct UserDefaultsList {
    public struct Permission {
        @UserDefaultWrapper<Bool>(key: UserDefaultKeys.isPermissionChecked.rawValue, defaultValue: false)
        public static var hasCompletedPermissionSetup
    }
}
