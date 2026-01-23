//
//  LobbyView.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

struct LobbyView: View {
    @Environment(AppRouter.self) private var router: AppRouter
    @State private var viewModel: LobbyViewModel
    @State private var channelListViewModel: ChannelListViewModel
    @State private var isAppearing = false

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
            viewModel.setup()
        }
        .onChange(of: viewModel.networkMode) { _, newMode in
            if newMode == .remote && viewModel.selectedChannelId == nil {
                Task { await channelListViewModel.fetchChannels() }
            }
        }
        .onChange(of: viewModel.matchStatus) { _, newValue in
            if case .gameReady(let peer) = newValue {
                // TODO: 연결 로직 수정 필요
                if UserDefaultsList.Game.isGuideChecked {
                    router.push(.game(peer, isNetwork: viewModel.networkMode == .remote))
                } else {
                    router.push(.operationGuide(me: viewModel.localPlayer,
                                                peer: peer, isNetwork: viewModel.networkMode == .remote))
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
        case .readyToSend, .sendingRequest, .requestDeclined:
            return true
        case .receivedInvite(_, let wasSoloGame):
            return !wasSoloGame
        default:
            return false
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
        
        playerOrbitSelector
        
        Spacer()
        
        bottomButtons(
            secondaryTitle: L10N.Lobby.remoteGalaxyButtonTitle,
            secondaryAction: {
                if viewModel.networkMode == .local {
                    viewModel.switchNetworkMode(to: .remote)
                } else {
                    viewModel.leaveChannel()
                }
            },
            showSecondary: viewModel.isNetworkAvailable)
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
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        
        Spacer()
        
        bottomButtons(
            secondaryTitle: L10N.Lobby.localGalaxyButtonTitle,
            secondaryAction: { viewModel.switchNetworkMode(to: .local) }
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
                viewModel.setSoloMode()
                if UserDefaultsList.Game.isGuideChecked {
                    router.push(.game(nil))
                } else {
                    router.push(.operationGuide(me: viewModel.localPlayer, peer: nil, isNetwork: viewModel.networkMode == .remote))
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
                    router.push(.settings)
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
                Text(viewModel.localPlayer.displayName)
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

// MARK: - Player Orbit Selector

private extension LobbyView {
    var playerOrbitSelector: some View {
        let displayPeers = viewModel.orderedPeers.prefix(OrbitSlot.orderedSlots.count)
        let isZoomedOut = displayPeers.count > 5
        let radarScale: CGFloat = isAppearing ? (isZoomedOut ? 0.8 : 1.0) : 0.1
        
        return GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                ZStack {
                    radarRings(size: size, center: center, isZoomedOut: isZoomedOut)

                    ForEach(Array(displayPeers.enumerated()), id: \.element.id) { index, player in
                        let position = calculatePosition(
                            index: index,
                            proximity: player.proximity,
                            size: size,
                            center: center,
                            isZoomedOut: isZoomedOut
                        )

                        peerPlayerView(player: player)
                            .position(position)
                            .id(player.id)
                    }
                }
                .scaleEffect(radarScale)

                localPlayerView
                    .position(center)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: radarScale)
            .onAppear {
                isAppearing = true
            }
            .onDisappear {
                isAppearing = false
            }
        }
        .frame(height: 400)
        .padding(.horizontal, 20)
    }

    func radarRings(size: CGFloat, center: CGPoint, isZoomedOut: Bool) -> some View {
        ZStack {
            ForEach([OrbitSlot.orbit1Radius, OrbitSlot.orbit2Radius, OrbitSlot.orbit3Radius], id: \.self) { factor in
                let adjustedFactor = isZoomedOut ? factor * OrbitSlot.zoomOutScale : factor
                Circle()
                    .stroke(
                        AppAsset.Color.rader.swiftUIColor.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: size * adjustedFactor * 2, height: size * adjustedFactor * 2)
                    .position(center)
            }
        }
    }

    func calculatePosition(index: Int, proximity: Double?, size: CGFloat, center: CGPoint, isZoomedOut: Bool) -> CGPoint {
        let slot = OrbitSlot.orderedSlots[index % OrbitSlot.orderedSlots.count]
        let angleRadians = CGFloat(slot.angleDegrees) * .pi / 180

        let proximityValue = proximity ?? OrbitSlot.defaultProximity
        var radiusFactor: CGFloat
        if proximityValue < OrbitSlot.proximityNearThreshold {
            radiusFactor = OrbitSlot.orbit1Radius
        } else if proximityValue < OrbitSlot.proximityFarThreshold {
            radiusFactor = OrbitSlot.orbit2Radius
        } else {
            radiusFactor = OrbitSlot.orbit3Radius
        }

        if isZoomedOut {
            radiusFactor *= OrbitSlot.zoomOutScale
        }

        let radius = size * radiusFactor
        return CGPoint(
            x: center.x + radius * cos(angleRadians),
            y: center.y + radius * sin(angleRadians)
        )
    }
}

// MARK: - Player Views

private extension LobbyView {
    var localPlayerView: some View {
        let labelOffset: CGFloat = -70

        return ZStack {
            playerLabel(text: viewModel.localPlayer.displayName)
                .offset(y: labelOffset)

            viewModel.localPlayer.avatar.image
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

    func peerPlayerView(player: PlayerInfo) -> some View {
        let isSelected = viewModel.selectedPeerID == player.id
        let labelOffset: CGFloat = -50

        return ZStack {
            playerLabel(text: player.displayName)
                .offset(y: labelOffset)

            player.avatar.image
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
                viewModel.selectPeer(player)
            }
        }
    }

    func playerLabel(text: String) -> some View {
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

        case .receivedInvite(let peer, let wasSoloGame):
            if !wasSoloGame {
                VStack {
                    Spacer()
                    inviteReceivedSheet(peer: peer)
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
                .ignoresSafeArea(edges: .bottom)
            }

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
    func requestModal(peer: PlayerInfo) -> some View {
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

    func modalAvatarView(for peer: PlayerInfo, isGrayscale: Bool) -> some View {
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

    func modalDisplayName(for peer: PlayerInfo) -> some View {
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
    func declineModal(peer: PlayerInfo) -> some View {
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

    func declineModalMessage(for peer: PlayerInfo) -> some View {
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
    func inviteReceivedSheet(peer: PlayerInfo) -> some View {
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

    func inviteSheetContent(for peer: PlayerInfo) -> some View {
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
            viewModel: container.makeLobbyViewModel(playerId: UUID(), nickname: "코스믹어드벤처", characterType: "character1"),
            channelListViewModel: container.makeChannelListViewModel()
        )
    }
}
