import Foundation

enum GameMessageType: String {
    case channelJoin
    case channelLeave
    case channelPlayerList
    case playerJoined
    case playerLeft

    case invite
    case inviteAccept
    case inviteDecline
    case inviteCancel

    case input

    case ping
    case pong
}
