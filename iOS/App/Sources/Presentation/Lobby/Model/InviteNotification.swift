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
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour], from: receivedAt, to: now)

        if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        } else {
            return "방금 전"
        }
    }
}
