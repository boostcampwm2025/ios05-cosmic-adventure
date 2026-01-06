//
//  PermissionSetupView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PermissionSetupView: View {
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
            Image("background")
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
    }
    
    private var backgoundImage: some View {
        ZStack {
            Circle()
                .fill(
                    Color("profileBackground")
                        .opacity(0.5)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 5)
                )
                .frame(width: 120, height: 120)
            
            Image("Character1")
                .resizable()
                .scaledToFit()
                .frame(width: 70)
        }
    }
    
    private var profileSection: some View {
        Group {
            Text(Constants.PermissionSetup.title)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(Color("mainLabel"))
            
            Text(Constants.PermissionSetup.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color("mainLabel"))
        }
    }
    
    private var permissionCardsSection: some View {
        VStack(spacing: 20) {
            PermissionCard(
                iconName: "permissionCameraIcon",
                title: Constants.PermissionSetup.Card.cameraTitle,
                subtitle: Constants.PermissionSetup.Card.cameraSubtitle
            )
            
            PermissionCard(
                iconName: "permissionNetworkIcon",
                title: Constants.PermissionSetup.Card.networkTitle,
                subtitle: Constants.PermissionSetup.Card.networkSubtitle
            )
        }
    }
    
    private var privacyNoticeText: some View {
        Text(Constants.PermissionSetup.privacyNotice)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Color("blackLabel").opacity(0.5))
    }
}

struct PermissionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionSetupView()
    }
}
