//
//  SettingsView.swift
//  App
//
//  Created by 영빈 on 1/21/26.
//

import SwiftUI

import StorageKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router: AppRouter
    @Environment(AppEntryManager.self) private var appEntryManager: AppEntryManager
    @State private var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        BackgroundContainerView(respectsSafeArea: true) {
            ScrollView {
                VStack(spacing: 32) {
                    profileSection
                    
                    gamePreviewSection
                    
                    sensitivitySection
                    
                    soundSection
                    
                    hapticSection
                    
                    previewSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10N.Settings.title)
                    .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 20))
                    .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.saveProfile(modelContext: modelContext)
                    router.pop()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Profile Section

private extension SettingsView {
    var profileSection: some View {
        SettingsProfileCard(
            nickname: $viewModel.nickname,
            selectedAvatar: $viewModel.selectedAvatar,
            avatars: viewModel.avatars,
            onAvatarSelected: { viewModel.selectAvatar($0) }
        )
    }
}

// MARK: - Sensitivity Section

private extension SettingsView {
    var sensitivitySection: some View {
        VStack(spacing: 20) {
            SettingsDiscreteSliderRow(
                title: L10N.Settings.jumpSensitivity,
                value: $viewModel.jumpSensitivity,
                labels: [L10N.Settings.low, L10N.Settings.medium, L10N.Settings.high]
            )
            
            SettingsDiscreteSliderRow(
                title: L10N.Settings.tiltSensitivity,
                value: $viewModel.tiltSensitivity,
                labels: [L10N.Settings.low, L10N.Settings.medium, L10N.Settings.high]
            )
        }
    }
}

// MARK: - Sound Section

private extension SettingsView {
    var soundSection: some View {
        SettingsDiscreteSliderRow(
            title: L10N.Settings.sound,
            value: $viewModel.soundVolume,
            labels: [L10N.Settings.low, L10N.Settings.medium, L10N.Settings.high]
        )
    }
}

// MARK: - Haptic Section

private extension SettingsView {
    var hapticSection: some View {
        SettingsToggleRow(
            title: L10N.Settings.haptic,
            isOn: $viewModel.isHapticsEnabled
        )
    }
}

// MARK: - Preview Section

private extension SettingsView {
    var previewSection: some View {
        SettingsDiscreteSliderRow(
            title: L10N.Settings.preview,
            value: $viewModel.facePreviewSize,
            labels: [L10N.Settings.small, L10N.Settings.medium, L10N.Settings.large]
        )
    }
}

// MARK: - Game Preview Section

private extension SettingsView {
    var gamePreviewSection: some View {
        Button {
            Task {
                guard await appEntryManager.canEnterGame() else { return }
                router.push(.testGamePreview)
            }
        } label: {
            Text(L10N.Settings.gamePreview)
                .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppAsset.Color.sheetSubBackground.swiftUIColor)
                .cornerRadius(8)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView(viewModel: .forPreview())
    }
    .environment(AppRouter())
}
#endif
