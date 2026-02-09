//
//  NotificationListView.swift
//  App
//
//  Created by 강윤서 on 2/9/26.
//

import SwiftUI

// MARK: - Notification List Popover (알림 리스트)

extension LobbyView {
    // 메인 팝오버 컨테이너
    var notificationListPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            notificationHeader

            if viewModel.inviteNotifications.isEmpty {
                notificationEmptyView
            } else {
                notificationScrollView
            }

            Spacer()
        }
        .padding(.vertical)
        .frame(width: 320, height: 350)
        .background(AppAsset.Color.sheetBackground.swiftUIColor)
    }

    // 헤더
    var notificationHeader: some View {
        HStack {
            Image(systemName: "envelope.fill")
                .resizable()
                .frame(width: 30, height: 22)
            Text(L10N.Lobby.NotificationListPopover.title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 24))
        }
        .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
        .padding(.horizontal)
    }

    // 알림이 없을 때 표시되는 뷰
    var notificationEmptyView: some View {
        VStack {
            AppAsset.Image.character1Explore.swiftUIImage
                .resizable()
                .frame(width: 140, height: 150)
                .padding(.bottom, 10)

            Text(L10N.Lobby.NotificationListPopover.notificationEmptyMessage)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 22))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                .frame(maxWidth: .infinity)

            Text(L10N.Lobby.NotificationListPopover.notificationEmptySubMessage)
                .font(AppFontFamily.Pretendard.medium.swiftUIFont(size: 16))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
        }
    }

    // 알림 스크롤 리스트
    var notificationScrollView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.inviteNotifications) { notification in
                    notificationRow(notification)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                }
            }
            .animation(.default, value: viewModel.inviteNotifications)
            .padding(.horizontal)
        }
    }

    // 알림 Row
    func notificationRow(_ notification: InviteNotification) -> some View {
        HStack(spacing: 12) {
            notification.sender.avatar.image
                .resizable()
                .frame(width: 40, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.sender.displayName)
                    .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                    .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                Text(notification.timeAgo)
                    .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 12))
                    .foregroundStyle(AppAsset.Color.subButton.swiftUIColor)
            }

            Spacer()

            notificationActionButtons(for: notification)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
    }

    // 수락/거절 버튼
    func notificationActionButtons(for notification: InviteNotification) -> some View {
        return HStack(spacing: 8) {
            // 수락 버튼
            PrimaryGradientButton(
                title: L10N.Lobby.NotificationListPopover.accept,
                cornerRadius: 10,
                verticalPadding: 8,
                fontSize: 16
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.acceptInviteFromNotification(notification)
                }
            }
            .frame(maxWidth: .infinity)

            // 거절 버튼
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.declineInviteFromNotification(notification)
                }
            }) {
                Text(L10N.Lobby.NotificationListPopover.decline)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppAsset.Color.subButton.swiftUIColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 140)
    }
}
