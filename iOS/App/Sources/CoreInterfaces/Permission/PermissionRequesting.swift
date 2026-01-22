//
//  PermissionRequesting.swift
//  App
//
//  Created by 강윤서 on 1/23/26.
//

protocol LocalNetworkPermissionRequesting {
    func requestPermission(hostName: String) async -> Bool
}

protocol NotificationPermissionRequesting {
    func requestPermission() async -> Bool
}
