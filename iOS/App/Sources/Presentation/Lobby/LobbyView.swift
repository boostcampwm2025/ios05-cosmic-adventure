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
    @State private var channelListViewModel: ChannelListViewModel

    init(viewModel: LobbyViewModel, channelListViewModel: ChannelListViewModel) {
        _viewModel = State(initialValue: viewModel)
        _channelListViewModel = State(initialValue: channelListViewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        BackgroundContainerView {
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                
                if viewModel.networkMode == .remote && viewModel.selectedChannelId == nil {
                    channelListContent
                } else {
                    lobbyContent
                }
            }
        }
        .onAppear {
            handleNetworkModeChange()
        }
        .onDisappear {
            viewModel.stopNetworkExploration()
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                handleNetworkModeChange()
            }
        }
        .onChange(of: viewModel.networkMode) { _, newMode in
            handleNetworkModeChange()
        }
        .onChange(of: viewModel.matchStatus) { _, newValue in
            if case .gameReady(let peer) = newValue {
                if UserDefaultsList.Game.isGuideChecked {
                    router.push(.gameReady(me: viewModel.myExplorer,
                                           peer: peer))
                } else {
                    router.push(.operationGuide(me: viewModel.myExplorer,
                                                peer: peer))
                }
            }
        }
        .alert(viewModel.activeAlert.title, isPresented: $viewModel.showPermissionAlert) {
            Button(viewModel.activeAlert.primaryButtonTitle) {
                if viewModel.activeAlert == .permissionDenied {
                    viewModel.openAppSettings()
                }
            }

            if viewModel.activeAlert.hasCancelButton {
                Button(L10N.Common.cancel, role: .cancel) { }
            }
        } message: {
            Text(viewModel.activeAlert.message)
        }
        .overlay {
            if isModalPresented {
                ZStack {
                    dimmedBackground
                    modalContent
                }
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.matchStatus)
    }

    private var isModalPresented: Bool {
        switch viewModel.matchStatus {
        case .readyToSend, .sendingRequest, .requestDeclined, .receivedInvite:
            return true
        default:
            return false
        }
    }
    
    private func handleNetworkModeChange() {
        viewModel.stopNetworkExploration()
        
        switch viewModel.networkMode {
        case .local:
            viewModel.startNetworkExploration()
        case .remote:
            if viewModel.selectedChannelId == nil {
                Task {
                    await channelListViewModel.fetchChannels()
                }
            } else {
                viewModel.startNetworkExploration()
            }
        }
    }
}

// MARK: - Lobby View Content

private extension LobbyView {
    @ViewBuilder
    var lobbyContent: some View {
        greetingCard
            .padding(.top, 40)
            .padding(.horizontal, 30)
        
        explorerOrbitSelector
        
        Spacer()
        
        bottomButtons(
            secondaryTitle: L10N.Lobby.remoteGalaxyButtonTitle,
            secondaryAction: { viewModel.switchToRemoteMode() },
            showSecondary: viewModel.isNetworkAvailable
        )
    }

    // TODO: 채널 목록 로드 실패 시 분기 처리 (네트워크 끊김 등)
    @ViewBuilder
    var channelListContent: some View {
        AppAsset.Image.titleLogo.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(height: 100)
            .padding(.top, 20)
        
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(channelListViewModel.channels) { channel in
                    // TODO: 채널 입장 후 연결 실패 시 분기 처리
                    ChannelRowView(channel: channel) {
                        viewModel.selectChannel(channel.id)
                        viewModel.startNetworkExploration()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        
        Spacer()
        
        bottomButtons(
            secondaryTitle: L10N.Lobby.localGalaxyButtonTitle,
            secondaryAction: { viewModel.switchToLocalMode() }
        )
    }
    
    @ViewBuilder
    func bottomButtons(
        secondaryTitle: LocalizedStringKey,
        secondaryAction: @escaping () -> Void,
        showSecondary: Bool = true
    ) -> some View {
        VStack(spacing: 12) {
            PrimaryGradientButton(title: L10N.Lobby.soloAdventureButtonTitle) {
                viewModel.startSoloAdventure()
                if UserDefaultsList.Game.isGuideChecked {
                    router.push(.game)
                } else {
                    router.push(.operationGuide(me: viewModel.myExplorer, peer: nil)) 
                }
            }
            
            if showSecondary {
                PrimaryGradientButton(title: secondaryTitle, isSubtle: true) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        secondaryAction()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
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
                Text(viewModel.myExplorer.displayName)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 22))
                Text(L10N.Lobby.greetingSuffix)
                    .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 22))
            }
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)

            Text(L10N.Lobby.greetingMessage)
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

// MARK: - Modal Content Views

private extension LobbyView {
    @ViewBuilder
    var dimmedBackground: some View {
        if case .gameReady = viewModel.matchStatus {
            EmptyView()
        } else {
            Color.black.opacity(0.7).ignoresSafeArea()
        }
    }

    @ViewBuilder
    var modalContent: some View {
        switch viewModel.matchStatus {
        case .readyToSend(let peer), .sendingRequest(let peer):
            requestModal(peer: peer)
                .transition(.opacity.combined(with: .scale))
                .padding(.horizontal, 24)

        case .receivedInvite(let peer):
            VStack {
                Spacer()
                inviteReceivedSheet(peer: peer)
            }
            .transition(.move(edge: .bottom))
            .zIndex(1)
            .ignoresSafeArea(edges: .bottom)

        case .requestDeclined(let peer):
            declineModal(peer: peer)
                .transition(.opacity.combined(with: .scale))
                .padding(.horizontal, 24)

        case .gameReady:
            EmptyView()

        default:
            EmptyView()
        }
    }
}

// MARK: - Request Modal Views
private extension LobbyView {
    func requestModal(peer: LobbyExplorer) -> some View {
        let isSending: Bool = {
            if case .sendingRequest = viewModel.matchStatus { return true }
            return false
        }()

        return VStack(spacing: 24) {
            modalTitle(L10N.Lobby.RequestModal.title)

            modalAvatarView(for: peer, isGrayscale: false)

            modalDisplayName(for: peer)

            HStack(spacing: 12) {
                requestButton(isSending: isSending)
                cancelButton
            }

            requestModalFooter(isSending: isSending)
        }
        .padding(24)
        .frame(height: 400)
        .background(AppAsset.Color.sheetBackground.swiftUIColor)
        .cornerRadius(30)
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
                .grayscale(isGrayscale ? 1.0 : 0.0)
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
            title: isSending ? L10N.Lobby.RequestModal.sendingButtonTitle : L10N.Lobby.RequestModal.requestButtonTitle,
            cornerRadius: 16,
            verticalPadding: 14
        ) {
            if !isSending { viewModel.sendInvite() }
        }
        .opacity(isSending ? 0.6 : 1.0)
        .disabled(isSending)
    }

    var cancelButton: some View {
        Button(action: viewModel.cancelInvite) {
            Text(L10N.Lobby.RequestModal.cancelButtonTitle)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppAsset.Color.subButton.swiftUIColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    func requestModalFooter(isSending: Bool) -> some View {
        Text(isSending ? L10N.Lobby.RequestModal.waitingMessage : L10N.Lobby.RequestModal.guideMessage)
            .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 12))
            .foregroundStyle(AppAsset.Color.subButton.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(height: 20)
            .animation(.none, value: isSending)
    }
}

// MARK: - Decline Modal Views

private extension LobbyView {
    func declineModal(peer: LobbyExplorer) -> some View {
        VStack(spacing: 24) {
            modalTitle(L10N.Lobby.DeclineModal.invitationDeclinedTitle)

            modalAvatarView(for: peer, isGrayscale: true)

            declineModalMessage(for: peer)

            declineModalConfirmButton

            declineModalFooter
        }
        .padding(24)
        .frame(height: 400)
        .background(AppAsset.Color.sheetBackground.swiftUIColor)
        .cornerRadius(30)
        .shadow(radius: 10)
    }

    func declineModalMessage(for peer: LobbyExplorer) -> some View {
        (Text("'\(peer.displayName)'") +
         Text(L10N.Lobby.DeclineModal.invitationDeclinedMessage))
        .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 18))
        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }

    var declineModalConfirmButton: some View {
        PrimaryGradientButton(
            title: L10N.Common.confirm,
            cornerRadius: 16,
            verticalPadding: 14
        ) {
            viewModel.confirmDecline()
        }
    }

    var declineModalFooter: some View {
        Text(L10N.Lobby.DeclineModal.guideMessage)
            .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 12))
            .foregroundStyle(AppAsset.Color.subButton.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(height: 20)
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
        .background(AppAsset.Color.sheetBackground.swiftUIColor)
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
        HStack {
            AppAsset.Image.inviteIcon.swiftUIImage
                .resizable()
                .frame(width: 24, height: 24)
            Text(L10N.Lobby.InviteReceivedSheet.title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
             Text(L10N.Lobby.InviteReceivedSheet.messageSuffix)
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
            title: L10N.Lobby.InviteReceivedSheet.acceptButton,
            cornerRadius: 16,
            verticalPadding: 14
        ) {
            viewModel.acceptInvite()
        }
    }

    var inviteDeclineButton: some View {
        Button(action: viewModel.declineInvite) {
            Text(L10N.Lobby.InviteReceivedSheet.declineButton)
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
        let container = AppContainer()
        LobbyView(
            viewModel: container.makeLobbyViewModel(nickname: "코스믹어드벤처", characterType: "character1"),
            channelListViewModel: container.makeChannelListViewModel()
        )
    }
}
