import Foundation

enum GameMessageType: String {
    case channelJoin                    // 클라이언트가 서버에게 채널 입장을 요청
    case channelLeave                   // 클라이언트가 서버에게 채널 퇴장을 요청
    case channelPlayerList
    case playerJoined                   // 서버가 클라이언트들에게 새로운 플레이어의 입장을 알림
    case playerLeft                     // 서버가 클라이언트들에게 특정 플레이어의 퇴장을 알림

    case invite
    case inviteAccept
    case inviteDecline
    case inviteCancel

    case gameReady
    case input

    case ping
    case pong
}
