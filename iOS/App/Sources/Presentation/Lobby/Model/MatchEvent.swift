//
//  MatchEvent.swift
//  App
//
//  Created by 강윤서 on 2/5/26.
//

import Foundation

enum MatchEvent: Equatable {
    // 유저 액션
    case selectPlayer(PlayerInfo)
    case deselectPlayer
    case startSoloGame

    // 초대 보내기
    case sendInvite
    case cancelOutboundInvite

    // 초대 받기
    case receiveInvite(from: PlayerInfo, wasSoloGame: Bool)
    case acceptInvite
    case declineInvite
    case inviteCancelled

    // 상대방 응답
    case inviteAccepted(by: PlayerInfo)
    case inviteDeclined(by: PlayerInfo)

    // 리셋
    case reset
}
