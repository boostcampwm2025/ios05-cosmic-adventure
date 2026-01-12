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

### 사전 요구사항

```bash
brew install tuist
```

### 초기 설정

```bash
make setup
```

### 실행

```bash
make ios        # iOS 앱 실행
make backend    # 백엔드 서버 실행
```

### 마이그레이션

```bash
make generate   # 마이그레이션 파일 생성
make migrate    # DB에 적용
make db-reset   # DB 초기화
```

### 기타

```bash
make test       # 테스트 실행
make clean      # 정리
```
