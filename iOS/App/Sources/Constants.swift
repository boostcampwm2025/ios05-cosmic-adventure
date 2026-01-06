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
}
