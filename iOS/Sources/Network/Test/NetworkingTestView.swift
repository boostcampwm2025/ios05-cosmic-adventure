//
//  NetworkingTestView.swift
//  iOS
//
//  Created by sungkug_apple_developer_ac on 12/18/25.
//

import SwiftUI

struct NetworkingTestView: View {

    @StateObject private var viewModel: NetworkingTestViewModel

    init() {
        let networking = NetworkFrameworkGameNetworking(
            serviceType: "_cosmic-adventure._tcp"
        )
        _viewModel = StateObject(
            wrappedValue: NetworkingTestViewModel(
                networking: networking
            )
        )
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Network Test")
                .font(.headline)

            Button("Start / Search") {
                viewModel.start()
            }

            Text(viewModel.stateText)
                .font(.subheadline)
                .foregroundColor(.gray)

            List(viewModel.peers) { peer in
                Button {
                    viewModel.connect(to: peer)
                } label: {
                    Text(peer.name)
                }
            }
        }
        .padding()
        .alert(
            "게임요청",
            isPresented: $viewModel.isIncomingRequestAlertPresented
        ) {
            Button("거절", role: .cancel) {
                viewModel.rejectIncomingRequest()
            }
            Button("수락") {
                viewModel.approveIncomingRequest()
            }
        } message: {
            Text("\(viewModel.incomingRequest?.name ?? "Unknown")이 게임을 요청했습니다.")
        }
    }
}
