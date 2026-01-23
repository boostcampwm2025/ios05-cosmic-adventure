//
//  NotificationManager.swift
//  App
//
//  Created by 강윤서 on 1/23/26.
//

import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private enum Action: String {
        case accept = "ACCEPT_ACTION"
        case decline = "DECLINE_ACTION"
    }

    private enum Category: String {
        case invite = "INVITE_CATEGORY"
    }

    @MainActor var onAcceptInvite: (() -> Void)?
    @MainActor var onDeclineInvite: (() -> Void)?

    private override init() {
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let acceptAction = UNNotificationAction(
            identifier: Action.accept.rawValue,
            title: L10N.InviteNotification.accept,
            options: .foreground
        )

        let declineAction = UNNotificationAction(
            identifier: Action.decline.rawValue,
            title: L10N.InviteNotification.decline,
            options: .destructive
        )

        let inviteCategory = UNNotificationCategory(
            identifier: Category.invite.rawValue,
            actions: [acceptAction, declineAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([inviteCategory])
    }

    func sendInviteNotification(from inviter: PlayerInfo) {
        let content = UNMutableNotificationContent()
        content.title = L10N.InviteNotification.title
        content.body = "\(inviter.displayName)" + L10N.InviteNotification.body
        content.sound = .default
        content.categoryIdentifier = Category.invite.rawValue

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            if actionIdentifier == Action.accept.rawValue {
                onAcceptInvite?()
            } else if actionIdentifier == Action.decline.rawValue {
                onDeclineInvite?()
            }
            
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
