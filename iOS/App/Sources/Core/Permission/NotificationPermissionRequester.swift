//
//  NotificationPermissionRequester.swift
//  App
//
//  Created by 강윤서 on 1/22/26.
//

import UserNotifications

final class NotificationPermissionRequester: NotificationPermissionRequesting {

    init() { }

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
}
