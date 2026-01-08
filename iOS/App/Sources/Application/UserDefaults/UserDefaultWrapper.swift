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
    
    init(key: String) {
        self.key = key
    }
    
    var wrappedValue: T? {
        get {
            UserDefaults.standard.object(forKey: key) as? T }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: key)
            } else {
                UserDefaults.standard.setValue(newValue, forKey: key)
            }
            
        }
    }
}
