//
//  ProfileSetupView.swift
//  App
//
//  Created by 영빈 on 1/7/26.
//

import SwiftUI

struct ProfileSetupView: View {
    @State private var viewModel = ProfileSetupViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        BackgroundContainerView {
            VStack(spacing: 0) {
                Group {
                    profilePreview
                        .padding(.top, 80)
                    
                    titleSection
                        .padding(.top, 16)
                    
                    nicknameSection
                        .padding(.top, 32)
                    
                    characterSection
                        .padding(.top, 28)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                PrimaryGradientButton(title: Constants.ProfileSetup.startButtonTitle) {
                    viewModel.proceedToLobby()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70)
            }
        }
    }
}

// MARK: - Profile Preview

private extension ProfileSetupView {
    var profilePreview: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(
                        AppAsset.Color.profileBackground.swiftUIColor
                            .opacity(0.5)
                    )
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 5)
                    )
                    .frame(width: 140, height: 140)
                
                viewModel.selectedAvatar.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90)
            }
        }
    }
    
    var titleSection: some View {
        Text(Constants.ProfileSetup.title)
            .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 25))
            .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
    }
}

// MARK: - Nickname Section

private extension ProfileSetupView {
    var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Constants.ProfileSetup.nicknameLabel)
                .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            
            TextField(
                "",
                text: $viewModel.nickname,
                prompt: Text(Constants.ProfileSetup.nicknamePlaceholder)
                    .foregroundStyle(AppAsset.Color.subBlackLabel.swiftUIColor)
            )
            .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 16))
            .foregroundStyle(AppAsset.Color.blackLabel.swiftUIColor)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Character Section

private extension ProfileSetupView {
    var characterSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Constants.ProfileSetup.characterLabel)
                .font(AppFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.avatars, id: \.self) { avatar in
                    characterGridItem(avatar: avatar)
                }
            }
        }
    }
    
    func characterGridItem(avatar: CharacterAvatar) -> some View {
        let isSelected = viewModel.selectedAvatar == avatar
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectAvatar(avatar)
            }
        } label: {
            avatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 95, height: 95)
                .opacity(isSelected ? 1.0 : 0.5)
                .background(
                    Circle()
                        .fill(.white.opacity(isSelected ? 0.3 : 0))
                        .frame(width: 110, height: 110)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: isSelected ? 3 : 0)
                        .frame(width: 110, height: 110)
                )
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Preview

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
    }
}
