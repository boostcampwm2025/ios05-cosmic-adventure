# ``Games``

## Overview
Games 모듈은 게임의 핵심 규칙과 상태를 책임지는 도메인 레이어입니다. 
입력·렌더링·물리(SwiftUI/SpriteKit/ARKit 등)와 분리된 순수 로직으로 
구성되어, 캐릭터 상태(이동/점프/접지), 점프 제약(더블 점프/쿨다운), 리스폰,
게임 종료(타임아웃/결승 도착) 같은 규칙을 일관되게 처리합니다. 
외부 시스템은 `GameInputProviding` 같은 추상화를 통해 입력을 주입하고,
화면/물리 레이어는 `GameplayManager`가 만든 상태와 이벤트를 해석해 
표현하도록 설계되어 테스트 및 확장이 쉽습니다.

## Topics
### Core
- ``GameplayManager``
- ``GameState``
