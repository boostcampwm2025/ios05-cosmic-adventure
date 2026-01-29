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

    /// 채널 목록의 로딩 상태를 구분하기 위한 enum.
    /// channels 배열이 비어있는 것이 '로딩 중'인지 '정말 없는 것'인지 구분할 수 없어
    /// 로딩 중에도 ChannelEmptyView가 표시되는 플리커를 방지한다.
    enum LoadState {
        case idle
        case loading
        case loaded
        case failed
    }
     
    private(set) var channels: [Channel] = []
    private(set) var loadState: LoadState = .idle
     
    private let channelService: ChannelServiceProtocol
    
    init(channelService: ChannelServiceProtocol) {
        self.channelService = channelService
    }
    
    func fetchChannels() async {
        // 중복 네트워크 요청 방지. 이미 로딩 중이면 무시.
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            channels = try await channelService.fetchChannels()
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }
}
