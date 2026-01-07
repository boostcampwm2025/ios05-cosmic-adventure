//
//  PermissionSetupView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PermissionSetupView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var permissionManager = PermissionManager()
    
    var body: some View {
        @Bindable var permissionManager = permissionManager
        
        ZStack {
            VStack(spacing: 0) {
                backgoundImage
                    .padding(.top, 100)
                    .padding(.bottom, 18)
                
                profileSection
                
                permissionCardsSection
                    .padding(.top, 26)
                
                Spacer()
                
                privacyNoticeText
                
                PrimaryGradientButton(title: Constants.PermissionSetup.requestButtonTitle) {
                    Task {
                        await permissionManager.requestPermissionsOnNextTapped()
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 70)
            }
            .padding(.horizontal, 20)
        }
        .background {
            AppAsset.Image.background.swiftUIImage
                .resizable()
                .scaledToFill()
        }
        .ignoresSafeArea()
        .alert(Constants.Common.permissionAlertTitle, isPresented: $permissionManager.showSettingsAlert) {
            Button(Constants.Common.goToSettings) { permissionManager.openAppSettings()
            }
            Button(Constants.Common.cancel, role: .cancel) { }
        } message: {
            Text(permissionManager.settingsAlertMessage)
        }
        .onAppear {
            permissionManager.refreshCameraState()
        }
        .onChange(of: permissionManager.shouldNavigateNext) {
            guard permissionManager.shouldNavigateNext else { return }
            router.push(.profileSetup)
            permissionManager.shouldNavigateNext = false
        }
    }
    
    private var backgoundImage: some View {
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
                .frame(width: 120, height: 120)
            
            AppAsset.Image.character1.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 70)
        }
    }
    
    private var profileSection: some View {
        Group {
            Text(Constants.PermissionSetup.title)
                .font(AppFontFamily.Pretendard.bold.swiftUIFont(size: 25))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
            
            Text(Constants.PermissionSetup.subtitle)
                .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 15))
                .foregroundStyle(AppAsset.Color.mainLabel.swiftUIColor)
                .padding(.top, 5)
        }
    }
    
    private var permissionCardsSection: some View {
        VStack(spacing: 20) {
            PermissionCard(
                iconImage: AppAsset.Image.permissionCameraIcon.swiftUIImage,
                title: Constants.PermissionSetup.Card.cameraTitle,
                subtitle: Constants.PermissionSetup.Card.cameraSubtitle
            )
            
            PermissionCard(
                iconImage: AppAsset.Image.permissionNetworkIcon.swiftUIImage,
                title: Constants.PermissionSetup.Card.networkTitle,
                subtitle: Constants.PermissionSetup.Card.networkSubtitle
            )
        }
    }
    
    private var privacyNoticeText: some View {
        Text(Constants.PermissionSetup.privacyNotice)
            .font(AppFontFamily.Pretendard.regular.swiftUIFont(size: 13))
            .foregroundStyle(
                AppAsset.Color.blackLabel.swiftUIColor
                    .opacity(0.5)
            )
    }
}

struct PermissionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionSetupView()
    }
}
