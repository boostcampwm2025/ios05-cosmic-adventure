//
//  InvitationPacket.swift
//  App
//
//  Created by soyoung on 1/9/26.
//

import NetworkKit

struct InvitationPacket: NetworkTransferable {
    let type: NetworkPacketType
    let senderIdentifier: String
}
