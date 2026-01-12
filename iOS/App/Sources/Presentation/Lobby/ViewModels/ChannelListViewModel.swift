//
//  ChannelListViewModel.swift
//  App
//
//  Created by 영빈 on 1/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ChannelListViewModel {
    
    private(set) var channels: [Channel] = []
    
    private let channelService: ChannelServiceProtocol
    
    init(channelService: ChannelServiceProtocol) {
        self.channelService = channelService
    }
    
    func fetchChannels() async {
        do {
            channels = try await channelService.fetchChannels()
        } catch {
            channels = []
        }
    }
}
