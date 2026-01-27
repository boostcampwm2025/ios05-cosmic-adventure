//
//  L10N.swift
//  App
//
//  Created by sungkug_apple_developer_ac on 1/6/26.
//

import SwiftUI

enum L10N {
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

            static let notificationTitle: LocalizedStringKey = "알림 권한"
            static let notificationSubtitle: LocalizedStringKey = "게임 중 초대 요청을 받기 위해 필요해요."
        }
        
        enum Alert {
            static let cameraAlert = "카메라 권한이 필요해요. 설정에서 카메라 접근을 허용해 주세요."
            static let localNetworkAlert = "근거리 통신(로컬 네트워크) 권한이 필요해요. 설정에서 로컬 네트워크 접근을 허용해 주세요."
            static let notificationAlert = "푸시 알림 권한이 필요해요. 설정에서 푸시 알림 접근을 허용해 주세요."
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
        static let soloAdventureButtonTitle: LocalizedStringKey = "혼자 모험 떠나기"
        static let remoteGalaxyButtonTitle: LocalizedStringKey = "더 먼 은하로 가기"
        static let localGalaxyButtonTitle: LocalizedStringKey = "근처의 은하 탐색하기"
        static let emptyGalaxyTitle: LocalizedStringKey = "떠날 수 있는 은하가 없어요"
        static let emptyGalaxySubtitle: LocalizedStringKey = "잠시 후 다시 찾아주세요"

        enum RequestModal {
            static let title: LocalizedStringKey = "함께 모험을 떠나요"
            static let requestButtonTitle: LocalizedStringKey = "요청하기"
            static let sendingButtonTitle: LocalizedStringKey = "요청 중..."
            static let cancelButtonTitle: LocalizedStringKey = "취소하기"
            static let guideMessage: LocalizedStringKey = "함께 떠나고 싶은 탐험가에게 요청을 보내세요"
            static let waitingMessage: LocalizedStringKey = "상대방의 수락을 기다리고 있어요"
        }

        enum DeclineModal {
            static let invitationDeclinedTitle: LocalizedStringKey = "모험 요청 거절"
            static let invitationDeclinedMessage: LocalizedStringKey = " 님이\n 모험 요청을 거절했습니다."
            static let guideMessage: LocalizedStringKey = "다른 탐험가에게 요청을 보내세요"
        }

        enum InviteReceivedSheet {
            static let title: LocalizedStringKey = "새로운 모험 요청"
            static let messageSuffix: LocalizedStringKey = " 님과 \n함께 모험을 떠나볼까요?"
            static let acceptButton: LocalizedStringKey = "수락하기"
            static let declineButton: LocalizedStringKey = "거절하기"
        }
    }
    
    enum Alert {
        static let defaultTitle: LocalizedStringKey = "오류 발생"
        static let localNetworkSubTitle: LocalizedStringKey = "근거리 통신(로컬 네트워크)으로 연결하기 위해 필요해요. 설정에서 권한을 허용해주세요."
        static let cameraSubTitle: LocalizedStringKey = "카메라 권한이 필요해요. 설정에서 권한을 허용해주세요."
        static let unknownSubTitle: LocalizedStringKey = "알 수 없는 네트워크 오류가 발생했습니다."
    }
    
    enum InviteNotification {
        static let title: String = String(localized: "초대요청")
        static let body: String = String(localized: "님이 게임에 초대했습니다!")
        
        static let accept: String = String(localized: "수락하기")
        static let decline: String = String(localized: "거절하기")
    }

    enum GameReady {
        static let connectingMessage = "다른 탐험가와 연결중.."
        static let waitingForPeerMessage = "상대방의 준비를 기다리는 중..."
        static let allReadyMessage = "모든 탐험가 준비 완료! 곧 시작합니다."
        static let soloPreparingMessage = "탐험 준비중..."
        static let soloReadyMessage = "탐험 준비 완료! 곧 시작합니다."
    }

    enum Settings {
        static let title: LocalizedStringKey = "설정"
        static let characterLabel: LocalizedStringKey = "캐릭터"
        
        static let jumpSensitivity: LocalizedStringKey = "점프 민감도"
        static let tiltSensitivity: LocalizedStringKey = "기울기 민감도"
        static let sound: LocalizedStringKey = "사운드"
        static let haptic: LocalizedStringKey = "진동"
        static let preview: LocalizedStringKey = "얼굴 미리보기 크기"
        
        static let low: LocalizedStringKey = "적게"
        static let medium: LocalizedStringKey = "중간"
        static let high: LocalizedStringKey = "높게"
        
        static let small: LocalizedStringKey = "작게"
        static let large: LocalizedStringKey = "크게"
    }
    
    enum Game {

        enum NodeName {
            static let platform = "platform"
            static let player = "player"
            static let leftWall = "leftWall"
            static let rightWall = "rightWall"
            static let monster = "monster"
            static let respawnButton = "respawnButton"
            static let respawnButtonLabel = "respawnButtonLabel"
        }
        
        enum Guide {
            static let moveManual: LocalizedStringKey = "동작 방법"
            static let horizontalMove: LocalizedStringKey = "고개를 좌우로 갸웃거리면\n앞으로 움직여요."
            static let jumpManual: LocalizedStringKey = "입을 오므리면 점프할 수 있어요."
            static let doubleJumpManual: LocalizedStringKey = "최대 2단 점프 가능해요."
            static let gotoVictoryCondition: LocalizedStringKey = "승리 조건 보기"

            static let victoryManual: LocalizedStringKey = "승리 방법"
            static let timeCondition: LocalizedStringKey = "제한 시간 1분 안에 결승점에 도착하세요."
            static let monsterCondition: LocalizedStringKey = "아래에서 모험을 방해하는 몬스터가\n올라오고 있으니 조심하세요."

            static let gameReady: LocalizedStringKey = "모험 준비 완료"
            static let neverShowAgain: LocalizedStringKey = "다시 보지 않기"
        }
    }
}
