//
//  UserDefaultWrapper.swift
//  App
//
//  Created by 강윤서 on 1/8/26.
//

import Foundation

@propertyWrapper
struct UserDefaultWrapper<T> {
    
    private let key: String
    private let defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
