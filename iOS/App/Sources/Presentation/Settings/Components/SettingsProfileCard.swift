//
//  SettingsProfileCard.swift
//  App
//
//  Created by 영빈 on 1/21/26.
//

import SwiftUI

struct SettingsProfileCard: View {
    @Binding var nickname: String
    @Binding var selectedAvatar: CharacterAvatar
    let avatars: [CharacterAvatar]
    let onAvatarSelected: (CharacterAvatar) -> Void
    
    @FocusState private var isNicknameFocused: Bool
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            avatarPreview
            nicknameField
            characterGrid
        }
    }
    
    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(AppAsset.Color.profileBackground.swiftUIColor.opacity(0.5))
                .overlay(Circle().stroke(.white, lineWidth: 5))
                .frame(width: 120, height: 120)
            
            selectedAvatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 80)
        }
    }
    
    private var nicknameField: some View {
        HStack {
            TextField("", text: $nickname)
                .accessibilityLabel(Text("Nickname"))
                .accessibilityHint(Text("Edit your display name"))
                .focused($isNicknameFocused)
                .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 16))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                .submitLabel(.done)
                .onSubmit {
                    isNicknameFocused = false
                }
            
            Image(systemName: "pencil")
                .foregroundStyle(AppAsset.Color.subButton.swiftUIColor)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(AppAsset.Color.sheetSubBackground.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var characterGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(avatars, id: \.self) { avatar in
                characterGridItem(avatar: avatar)
            }
        }
    }
    
    private func characterGridItem(avatar: CharacterAvatar) -> some View {
        let isSelected = selectedAvatar == avatar
        
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onAvatarSelected(avatar)
            }
        } label: {
            avatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .opacity(isSelected ? 1.0 : 0.5)
                .background(
                    Circle()
                        .fill(.white.opacity(isSelected ? 0.3 : 0))
                        .frame(width: 80, height: 80)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: isSelected ? 3 : 0)
                        .frame(width: 80, height: 80)
                )
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .accessibilityLabel(Text(String(describing: avatar)))
    }
}
