# Cosmic Adventure

언제나, 어디서나 환경에 구애받지 않고 우주를 탐험할 수 있는 코스믹 어드벤처에 오신 것을 환영합니다!

<img width="225" height="214" alt="image" src="https://github.com/user-attachments/assets/7bf9289d-58e3-44ed-823b-e105c2067e78" />

[지금 바로 다운로드하기](https://appbox.me/e1ij383b)

## 프로젝트 환경

|항목 | 내용|
|:--|:--|
|최소 버전 | iOS 18.0+|
|UI 프레임워크 | SwiftUI|
|데이터 관리 | SwiftData|

## 프로젝트 구조

<img width="600" alt="image" src="https://github.com/user-attachments/assets/a370e957-dfde-466b-9499-e0d10e439461" />

- App: 앱 모듈
- InputSystem: InputEvent 관련 처리 모듈
- Games: 게임 룰 관련 모듈
- GameEngineCore: 게임 물리 엔진 모듈
- NetworkKit: 네트워크 관련 모듈

## Development

프로젝트를 실행하기 위해 다음의 명령어로 Tuist를 설치해야 합니다.

```bash
brew install tuist
```

다음의 명령어로 프로젝트를 생성하고 실행할 수 있습니다.

```bash
# tuist generate
tuist install
tuist generate

# iOS
tuist run iOS

# Backend
cd backend
swift run App
```
