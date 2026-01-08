//
//  Constants.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

enum Constants {
    enum Common {
        static let permissionAlertTitle: LocalizedStringKey = "권한이 필요해요"
        static let goToSettings: LocalizedStringKey = "설정으로 이동"
        static let cancel: LocalizedStringKey = "취소"
        static let confirm: LocalizedStringKey = "확인"
    }
    
    enum PermissionSetup {
        static let title: LocalizedStringKey = "우주 수호자 설정"
        static let subtitle: LocalizedStringKey = "게임을 시작하기 위해 몇 가지 권한이 필요해요."
        static let privacyNotice: LocalizedStringKey = "저희는 개인 정보를 수집하지 않습니다."
        static let requestButtonTitle: LocalizedStringKey = "권한 요청하기"

        enum Card {
            static let cameraTitle: LocalizedStringKey = "카메라 권한"
            static let cameraSubtitle: LocalizedStringKey = "AR 게임 플레이를 위해 필요해요."

            static let networkTitle: LocalizedStringKey = "근거리 통신 권한"
            static let networkSubtitle: LocalizedStringKey = "다른 플레이어와 연결하기 위해 필요해요."
        }
    }

    enum ProfileSetup {
        static let title: LocalizedStringKey = "프로필 설정"
        static let nicknameLabel: LocalizedStringKey = "Nickname"
        static let nicknamePlaceholder: LocalizedStringKey = "건방진 탐험가 123"
        static let characterLabel: LocalizedStringKey = "Character"
        static let startButtonTitle: LocalizedStringKey = "시작할 준비가 되었나요?"
    }
    
    enum Lobby {
        static let greetingSuffix: LocalizedStringKey = " 님 함께"
        static let greetingMessage: LocalizedStringKey = "모험을 떠날 탐험가를 골라주세요"
        static let startButtonTitle: LocalizedStringKey = "혼자 모험 떠나기"
    }
    
    enum Game {
        enum NodeName {
            static let platform = "platform"
            static let player = "player"
            static let leftWall = "leftWall"
            static let rightWall = "rightWall"
        }
    }
    
    enum Alert {
        static let defaultTitle: LocalizedStringKey = "오류 발생"
        static let localNetworkSubTitle: LocalizedStringKey = "근거리 통신(로컬 네트워크)으로 연결하기 위해 필요해요. 설정에서 권한을 허용해주세요."
        static let unknownSubTitle: LocalizedStringKey = "알 수 없는 네트워크 오류가 발생했습니다."
    }
}
