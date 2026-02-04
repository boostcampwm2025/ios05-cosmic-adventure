//
//  ConnectionHandling.swift
//  NetworkKit
//
//  Created by 강윤서 on 2/5/26.
//

import Foundation
import Network
import os

protocol ConnectionHandling: AnyObject {
    var onDataReceived: ((Data, NWConnection) -> Void)? { get }
    var onConnectionFailed: ((NWConnection) -> Void)? { get }
    var connectionLogger: Logger { get }

    func removeConnection(_ connection: NWConnection)
}
