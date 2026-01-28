//
//  InviteNotification.swift
//  App
//
//  Created by soyoung on 1/28/26.
//

import Foundation

struct InviteNotification: Identifiable, Equatable {
    let id: UUID = UUID()
    let sender: PlayerInfo
    let receivedAt: Date = Date()

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: receivedAt, relativeTo: Date())
    }
}
