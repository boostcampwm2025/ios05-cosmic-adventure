//
//  LobbyView.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

struct LobbyView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppRouter.self) private var router: AppRouter
    @State private var viewModel: LobbyViewModel

    init(viewModel: LobbyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            BackgroundContainerView {
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 60)
                        .padding(.horizontal, 20)

                    greetingCard
                        .padding(.top, 40)
                        .padding(.horizontal, 30)

                    explorerOrbitSelector

                    Spacer()

                    PrimaryGradientButton(title: Constants.Lobby.startButtonTitle) {
                        viewModel.startSoloAdventure()
                        router.push(.game)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 70)
                }
            }
            .onAppear {
                viewModel.startNetworkExploration()
            }
            .onDisappear {
                viewModel.stopNetworkExploration()
            }
            .onChange(of: scenePhase, { oldValue, newValue in
                if newValue == .active {
                    viewModel.startNetworkExploration()
                }
            })
            .alert(viewModel.activeAlert.title, isPresented: $viewModel.showPermissionAlert) {
                Button(viewModel.activeAlert.primaryButtonTitle) {
                    if viewModel.activeAlert == .permissionDenied {
                        viewModel.openAppSettings()
                    }
                }

                if viewModel.activeAlert.hasCancelButton {
                    Button(Constants.Common.cancel, role: .cancel) { }
                }
            } message: {
                Text(viewModel.activeAlert.message)
            }

            switch viewModel.matchStatus {
            case .readyToSend(let peer), .sendingRequest(let peer):
                Color.black.opacity(0.7).ignoresSafeArea()

                requestModal(peer: peer)
                    .transition(.opacity.combined(with: .scale))

            case .receivedInvite(let peer):
                Color.black.opacity(0.7).ignoresSafeArea()

                VStack {
                    Spacer()
                    inviteReceivedSheet(peer: peer)
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
                .ignoresSafeArea(edges: .bottom)

            case .requestDeclined(let peer):
                Color.black.opacity(0.7).ignoresSafeArea()

                declineModal(peer: peer)
                    .transition(.opacity.combined(with: .scale))

                //            case .gameReady(let peer):
                //                // TODO: GameReadyView 로 전환
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.matchStatus)
    }
}

// MARK: - Top Bar

private extension LobbyView {
    var topBar: some View {
        HStack {
            Spacer()

            HStack(spacing: 12) {
                topBarButton(systemName: "trophy") {
                    // TODO: RankingView로 연결
                }

                topBarButton(systemName: "bell") {
                    // TODO: NotificationView로 연결
                }

                topBarButton(systemName: "gearshape") {
                    // TODO: SettingsView로 연결
                }
            }
        }
    }

    func topBarButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [
                            AppAsset.Color.iconGradientStart.swiftUIColor,
                            AppAsset.Color.iconGradientEnd.swiftUIColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
        }
    }
}

// MARK: - Greeting Card

private extension LobbyView {
    var greetingCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Text(viewModel.userName)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 22))
                Text(Constants.Lobby.greetingSuffix)
                    .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 22))
            }
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)

            Text(Constants.Lobby.greetingMessage)
                .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 22))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            AppAsset.Color.permissionCardBackground.swiftUIColor
                .opacity(0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Explorer Orbit Selector

private extension LobbyView {
    var explorerOrbitSelector: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                radarRings(size: size, center: center)

                ForEach(Array(viewModel.orderedPeers.enumerated()), id: \.element.id) { index, explorer in
                    let slot = OrbitSlot.orderedSlots[index]
                    let position = calculatePosition(slot: slot, size: size, center: center)

                    peerExplorerView(explorer: explorer)
                        .position(position)
                }

                myExplorerView
                    .position(center)
            }
        }
        .padding(.horizontal, 20)
    }

    func radarRings(size: CGFloat, center: CGPoint) -> some View {
        ZStack {
            ForEach([OrbitSlot.orbit1Top.radiusFactor, OrbitSlot.orbit2LeftTop.radiusFactor, OrbitSlot.orbit3LeftBottom.radiusFactor], id: \.self) { factor in
                Circle()
                    .stroke(
                        AppAsset.Color.rader.swiftUIColor.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: size * factor * 2, height: size * factor * 2)
                    .position(center)
            }
        }
    }

    func calculatePosition(slot: OrbitSlot, size: CGFloat, center: CGPoint) -> CGPoint {
        let radius = size * slot.radiusFactor
        let angleRadians = CGFloat(slot.angleDegrees) * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(angleRadians),
            y: center.y + radius * sin(angleRadians)
        )
    }
}

// MARK: - Explorer Views

private extension LobbyView {
    var myExplorerView: some View {
        let labelOffset: CGFloat = -70

        return ZStack {
            explorerLabel(text: viewModel.myExplorer.displayName)
                .offset(y: labelOffset)

            viewModel.myExplorer.avatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 110, height: 110)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 110, height: 110)
                )
        }
    }

    func peerExplorerView(explorer: LobbyExplorer) -> some View {
        let isSelected = viewModel.selectedPeerID == explorer.id
        let labelOffset: CGFloat = -50

        return ZStack {
            explorerLabel(text: explorer.displayName)
                .offset(y: labelOffset)

            explorer.avatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .background(
                    Circle()
                        .fill(.white.opacity(isSelected ? 0.25 : 0))
                        .frame(width: 80, height: 80)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: isSelected ? 3 : 0)
                        .frame(width: 80, height: 80)
                )
                .shadow(
                    color: .white.opacity(isSelected ? 0.35 : 0),
                    radius: isSelected ? 10 : 0
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                viewModel.selectPeer(explorer)
            }
        }
    }

    func explorerLabel(text: String) -> some View {
        Text(text)
            .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 12))
            .foregroundStyle(AppAsset.Color.blackLabel.swiftUIColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.white.opacity(0.85))
            )
    }
}

// MARK: - Request Modal Views
private extension LobbyView {
    func requestModal(peer: LobbyExplorer) -> some View {
        let isSending: Bool = {
            if case .sendingRequest = viewModel.matchStatus { return true }
            return false
        }()

        return VStack(spacing: 0) {
            modalTitle(Constants.Lobby.RequestModal.title)

            Spacer()

            modalAvatarView(for: peer, isGrayscale: false)

            Spacer()

            modalDisplayName(for: peer)

            Spacer()

            HStack(spacing: 12) {
                requestButton(isSending: isSending)
                cancelButton
            }
            .padding(.top, 10)

            requestModalFooter(isSending: isSending)
        }
        .padding(30)
        .frame(height: 400)
        .background(AppAsset.Color.subSelect.swiftUIColor)
        .cornerRadius(30)
        .padding(.horizontal, 24)
        .shadow(radius: 10)
    }

    func modalTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
    }

    func modalAvatarView(for peer: LobbyExplorer, isGrayscale: Bool) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.5))
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

            peer.avatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 85, height: 85)
                .grayscale(isGrayscale ? 1.0 : 0.0) // 흑백 여부 처리
                .opacity(isGrayscale ? 0.8 : 1.0)
        }
    }

    func modalDisplayName(for peer: LobbyExplorer) -> some View {
        Text(peer.displayName)
            .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 20))
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
    }

    func requestButton(isSending: Bool) -> some View {
        PrimaryGradientButton(
            title: isSending ? Constants.Lobby.RequestModal.sendingButtonTitle : Constants.Lobby.RequestModal.requestButtonTitle,
            cornerRadius: 16,
            verticalPadding: 14
        ) {
            if !isSending { viewModel.sendInviteRequest() }
        }
        .opacity(isSending ? 0.6 : 1.0)
        .disabled(isSending)
    }

    var cancelButton: some View {
        Button(action: viewModel.cancelInviteRequest) {
            Text(Constants.Lobby.RequestModal.cancelButtonTitle)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppAsset.Color.subButton.swiftUIColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    func requestModalFooter(isSending: Bool) -> some View {
        Text(isSending ? Constants.Lobby.RequestModal.waitingMessage : Constants.Lobby.RequestModal.guideMessage)
            .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 12))
            .foregroundStyle(AppAsset.Color.subButton.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(height: 20)
            .padding(.top, 16)
            .animation(.none, value: isSending)
    }
}

// MARK: - Decline Modal Views

private extension LobbyView {
    func declineModal(peer: LobbyExplorer) -> some View {
        VStack(spacing: 0) {
            modalTitle(Constants.Lobby.DeclineModal.invitationDeclinedTitle)

            Spacer()

            modalAvatarView(for: peer, isGrayscale: true)

            Spacer()

            declineModalMessage(for: peer)

            Spacer()

            declineModalConfirmButton

            declineModalFooter
        }
        .padding(30)
        .frame(height: 400)
        .background(AppAsset.Color.subSelect.swiftUIColor)
        .cornerRadius(30)
        .padding(.horizontal, 24)
        .shadow(radius: 10)
    }

    func declineModalMessage(for peer: LobbyExplorer) -> some View {
        (Text("'\(peer.displayName)'") +
         Text(Constants.Lobby.DeclineModal.invitationDeclinedMessage))
        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 18))
        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
        .multilineTextAlignment(.center)
    }

    var declineModalConfirmButton: some View {
        PrimaryGradientButton(
            title: Constants.Common.confirm,
            cornerRadius: 16,
            verticalPadding: 14
        ) {
            viewModel.confirmDecline()
        }
        .padding(.top, 10)
    }

    var declineModalFooter: some View {
        Text(Constants.Lobby.DeclineModal.guideMessage)
            .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 12))
            .foregroundStyle(AppAsset.Color.subButton.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(height: 20)
            .padding(.top, 16)
    }
}

// MARK: - 초대 수신 Bottom Sheet

private extension LobbyView {
    func inviteReceivedSheet(peer: LobbyExplorer) -> some View {
        VStack(spacing: 24) {
            inviteSheetHeader

            inviteSheetContent(for: peer)

            HStack(spacing: 12) {
                inviteAcceptButton
                inviteDeclineButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 40)
        .background(AppAsset.Color.subSelect.swiftUIColor)
        
        .clipShape(
            .rect(
                topLeadingRadius: 30,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 30
            )
        )
        .shadow(radius: 10)
    }

    var inviteSheetHeader: some View {
        Text(Constants.Lobby.InviteReceivedSheet.title)
            .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func inviteSheetContent(for peer: LobbyExplorer) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

                peer.avatar.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 85, height: 85)
            }

            (Text("'\(peer.displayName)'")
                .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 22))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
             +
             Text(Constants.Lobby.InviteReceivedSheet.messageSuffix)
                .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 20))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            )
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
    }

    var inviteAcceptButton: some View {
        PrimaryGradientButton(
            title: Constants.Lobby.InviteReceivedSheet.acceptButton,
            cornerRadius: 16,
            verticalPadding: 14
        ) {
            viewModel.acceptInvite()
        }
    }

    var inviteDeclineButton: some View {
        Button(action: viewModel.declineInvite) {
            Text(Constants.Lobby.InviteReceivedSheet.declineButton)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppAsset.Color.subButton.swiftUIColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Preview

struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView(viewModel: AppContainer().makeLobbyViewModel())
    }
}
