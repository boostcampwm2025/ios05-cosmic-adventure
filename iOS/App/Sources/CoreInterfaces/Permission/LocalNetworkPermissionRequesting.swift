//
//  LocalNetworkPermissionRequesting.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/8/26.
//

protocol LocalNetworkPermissionRequesting {
    func requestPermission(hostName: String) async -> Bool
}
