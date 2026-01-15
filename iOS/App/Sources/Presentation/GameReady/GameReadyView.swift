//
//  GameReadyView.swift
//  App
//
//  Created by soyoung on 1/15/26.
//

import SwiftUI

struct GameReadyView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    @State private var viewModel: GameReadyViewModel
    @State private var isAnimating = false

    init(viewModel: GameReadyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BackgroundContainerView {
            VStack(spacing: 0) {
                Spacer()

                HStack(spacing: 10) {
                    characterView(explorer: viewModel.me, isMe: true)
                        .offset(y: isAnimating ? -15 : 0) // 위아래 둥둥 효과
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    characterView(explorer: viewModel.peer, isMe: false)
                        .offset(y: isAnimating ? 0 : -15) // 엇박자로 움직임
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.5),
                            value: isAnimating
                        )
                }
                .padding(.bottom, 30)

                VStack(spacing: 16) {
                    customProgressBar
                        .padding(.horizontal, 60)

                    Text(viewModel.message)
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 18))
                        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                }

                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            viewModel.checkInitialStatus()
        }
        .onChange(of: viewModel.isMeReady) { _, _ in attemptStart() }
        .onChange(of: viewModel.isPeerReady) { _, _ in attemptStart() }
    }

    private func attemptStart() {
        if viewModel.checkAllReady() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                router.push(.game)
            }
        }
    }
}

// MARK: - Subviews

private extension GameReadyView {

    func characterView(explorer: LobbyExplorer, isMe: Bool) -> some View {
        VStack(spacing: 10) {
            explorer.avatar.image
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
            viewModel: container.makeGameReadyViewModel(me: LobbyExplorer(role: .me, displayName: "나", avatar: .character1),
                                                        peer: LobbyExplorer(role: .peer, displayName: "상대", avatar: .character2))
        )
    }
}
