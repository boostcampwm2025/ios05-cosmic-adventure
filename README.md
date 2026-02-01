# Cosmic Adventure

언제나, 어디서나 환경에 구애받지 않고 우주를 탐험할 수 있는 코스믹 어드벤처에 오신 것을 환영합니다!

## 프로젝트 환경

|항목 | 내용|
|:--|:--|
|최소 버전 | iOS 18.0+|
|UI 프레임워크 | SwiftUI|
|데이터 관리 | SwiftData|

## **주요 기능 소개**

### **온보딩**

<img width="300" alt="image" src="https://github.com/user-attachments/assets/41176fac-95c9-46fb-bf17-cfaa7f09d921" />

<img width="300"  alt="image" src="https://github.com/user-attachments/assets/def0bc17-414f-454c-9301-3f53c77421ad" />

- **사용 권한 설정**: 카메라 / 근거리 통신 / 알림 권한 안내 및 설정
- **프로필 설정**: 닉네임 + 캐릭터 선택으로 나만의 또잉또잉스 생성


### **홈: 동료 찾기**
<img src="https://github.com/user-attachments/assets/691e74bc-3794-443c-8cd3-994363aba89d" width="300" />

**A) 채널 매칭(서버 기반)**

- 서버 통신이 가능한 환경에서 사용
- 원거리 플레이어와 연결 가능
- 채널 혼잡도 기반 오토스케일링
    - Scale-Out**:** 채널 점유율이 80% 초과 시, 추가 채널 할당
    - Scale-In: 비어있는 채널 발생 시 자원 정리

**B) 근거리 탐색(P2P)**

- 인터넷 없이도 가능
- 주변 유저를 직접 탐색해서 연결


### **매칭 흐름**
<img src="https://github.com/user-attachments/assets/fe168867-ebc2-4499-a72b-5e993aa99986" width="300" />
<img src="https://github.com/user-attachments/assets/422247b2-c63c-49dd-b5d6-b39fea8d9250" width="300" />

- 원하는 유저에게 **초대 요청**
- 상대가 **수락**하고, 두 플레이어가 준비 완료 시 게임 맵 진입
- 여러 요청이 오면 **알림 목록에서 한꺼번에 관리**
    - 목록에서도 수락/거절 가능
    - 목록 보는 중 새 요청이 오면 즉시 처리 UI 제공


### **게임 온보딩**

<img width="700" alt="image" src="https://github.com/user-attachments/assets/bb091a5d-e4a7-421d-9b15-b4914957d47f" />

- **고개 갸웃(좌/우)**: 좌우 이동
- **입 오므리기**: 점프
    - 1단 점프: 입술 내밀기
    - 연속 동작으로 최대 2단 점프까지 가능
- **2인 모드 승리 조건**: 몬스터를 피해 **더 빠르게 결승점 도달**하는 사람이 승리


### **게임 모드 & 플레이 경험**

### **✅ 2인 모드**
<img src="https://github.com/user-attachments/assets/fe5e7e25-6fa1-40ee-bb29-7a4ec73560b4" width="300" />

- 상대의 **비디오 피드 + 캐릭터 상태가 실시간 동기화**
- 상대 캐릭터는 **반투명** 처리
    - 시야 방해 최소화
    - “함께” 플레이하는 느낌 강화

### **✅ 1인 모드**
<img src="https://github.com/user-attachments/assets/c06dbb18-c603-4ad5-8b15-3df295914ba2" width="300" />

- 동일한 방식으로 플레이 가능
- 몬스터에 닿으면 즉시 리스폰
- 우측 상단 버튼으로 수동 리스폰도 지원
- 플레이 중 초대가 오면 **배너 알림**으로 바로 참여 가능

### **✅ 결과 화면**
<img src="https://github.com/user-attachments/assets/e0fd63c0-3b43-41fc-8ab0-0cf445b82a56" width="300" />

- 게임 종료 시 결과를 보여주고
- 결승점에는 또잉또잉스를 탈출시켜줄 **우주선**이 대기


### **환경 설정(튜닝/테스트)**
<img src="https://github.com/user-attachments/assets/30a76f11-89fe-4f31-98d1-7f51d5c60094" width="300" />
- 감도 조절
- PIP 크기 조절
- 사운드 볼륨 조절
- 테스트 뷰(게임 미리보기)
    - 설정값이 실제 플레이에 어떻게 적용되는지 즉시 확인

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

