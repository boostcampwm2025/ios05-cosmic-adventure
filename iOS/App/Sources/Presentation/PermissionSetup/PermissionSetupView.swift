//
//  PermissionSetupView.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

struct PermissionSetupView: View {
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some View {
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

                PrimaryGradientButton(
                    title: "권한 요청하기"
                ) {
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
        .alert("권한이 필요해요", isPresented: $permissionManager.showSettingsAlert) {
            Button("설정으로 이동") { permissionManager.openAppSettings() }
            Button("취소", role: .cancel) {}
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
            Text("우주 수호자 설정")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(Color("mainLabel"))

            Text("게임을 시작하기 위해 몇 가지 권한이 필요해요.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color("mainLabel"))
        }
    }
    
    private var permissionCardsSection: some View {
        VStack(spacing: 20) {
            PermissionCard(
                iconName: "permissionCameraIcon",
                title: "카메라 권한",
                subtitle: "AR 게임 플레이를 위해 필요해요.",
            )

            PermissionCard(
                iconName: "permissionNetworkIcon",
                title: "근거리 통신 권한",
                subtitle: "다른 플레이어와 연결하기 위해 필요해요.",
            )
        }
    }
    
    private var privacyNoticeText: some View {
        Text("저희는 개인 정보를 수집하지 않습니다.")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Color("blackLabel").opacity(0.5))
    }
}

struct PermissionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionSetupView()
    }
}
