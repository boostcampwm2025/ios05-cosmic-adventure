//
//  GameReadyView.swift
//  App
//
//  Created by soyoung on 1/15/26.
//

import SwiftUI

struct GameReadyView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    @Environment(AppEntryManager.self) private var appEntryManager
    @State private var viewModel: GameReadyViewModel
    @State private var isAnimating = false
    @State private var didScheduleStart = false
    @State private var startTask: Task<Void, Never>?

    init(viewModel: GameReadyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BackgroundContainerView {
            VStack(spacing: 0) {
                Spacer()

                HStack(spacing: 10) {
                    characterView(player: viewModel.localPlayer)
                        .offset(y: isAnimating ? -15 : 0) // 위아래 둥둥 효과
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    if let peer = viewModel.remotePlayer {
                        characterView(player: peer)
                            .offset(y: isAnimating ? 0 : -15) // 엇박자로 움직임
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.5),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 30)

                VStack(spacing: 16) {
                    customProgressBar
                        .padding(.horizontal, 60)

                    Text(viewModel.message)
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            isAnimating = true
            viewModel.setMyReady()
            attemptStart()
        }
        .onDisappear {
            viewModel.stopTimer()
            startTask?.cancel()
        }
        .onChange(of: viewModel.isMeReady) { _, _ in attemptStart() }
        .onChange(of: viewModel.isPeerReady) { _, _ in attemptStart() }
        .onChange(of: viewModel.scheduledStartAt) { _, _ in attemptStart() }
    }

    private func attemptStart() {
        guard let startAt = viewModel.scheduledStartAt else { return }
        guard didScheduleStart == false else { return }
        didScheduleStart = true
        let delay = max(0, startAt - Date().timeIntervalSince1970)
        
        startTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            guard await appEntryManager.canEnterGame() else {
                didScheduleStart = false
                return
            }
            router.push(.game(viewModel.remotePlayer, isNetwork: viewModel.isNetwork))
        }
    }
}

// MARK: - Subviews

private extension GameReadyView {

    func characterView(player: PlayerInfo) -> some View {
        VStack(spacing: 10) {
            player.avatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
        }
    }

    var customProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 16)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppAsset.Color.buttonGradientStart.swiftUIColor,
                                AppAsset.Color.buttonGradientEnd.swiftUIColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width * viewModel.progress, height: 16)
                    .animation(.linear(duration: 0.1), value: viewModel.progress)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: viewModel.progress)
            }
        }
        .frame(height: 16)
    }
}

// MARK: - Preview

struct GameReadyView_Previews: PreviewProvider {
    static var previews: some View {
        let container = AppContainer()
        GameReadyView(
            viewModel: container.makeGameReadyViewModel(localPlayer: PlayerInfo(role: .local, displayName: "나", avatar: .character1),
                                                        remotePlayer: PlayerInfo(role: .remote, displayName: "상대", avatar: .character2),
                                                        isNetwork: false)
        )
    }
}
