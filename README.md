# Cosmic Adventure

언제나, 어디서나 환경에 구애받지 않고 우주를 탐험할 수 있는 코스믹 어드벤처에 오신 것을 환영합니다!

## 목차
- [주요 기능 소개](#주요-기능-소개)
- [개발 환경 및 버전 정보](#개발-환경-및-버전-정보)
- [기술 스택 및 도입 이유](#기술-스택-및-도입-이유)
- [프로젝트 진행 방식](#프로젝트-진행-방식)
- [Development](#development)



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

## 개발 환경 및 버전 정보
![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)  
![iOS](https://img.shields.io/badge/iOS-18.0+-black?logo=apple)  
![Xcode](https://img.shields.io/badge/Xcode-16.0+-blue?logo=xcode)  
![Vapor](https://img.shields.io/badge/Vapor-4.115-blue?logo=vapor)  
![Tuist](https://img.shields.io/badge/Tuist-4.99.0-blue?logo=tuist)  

## 기술 스택 및 도입 이유

### 🌐 실시간 통신 및 네트워크
- **Network.framework**
    - **도입 이유**: `URLSession`보다 낮은 수준(Low-level)에서 TCP/UDP 및 TLS 연결을 직접 제어하여 오버헤드를 줄이고, 저지연 실시간 P2P 통신을 구현하기 위해 채택했습니다.
    - **활용**: `Bonjour`를 통한 주변 기기 탐색과 TCP 연결을 통해 별도의 중앙 서버 없이 로컬 환경에서 멀티플레이어 환경을 구축합니다.
- **WebSocket**
    - **도입 이유**: 클라이언트와 서버 간의 양방향 실시간 데이터 교환을 위해 채택했습니다.
    - **활용**: Vapor 백엔드 서버와 연결되어 실시간 사용자 상태 동기화, 매칭 시스템 및 게임 데이터 중계를 담당합니다.

### 🎥 비디오 및 미디어 처리
- **VideoToolbox**
    - **도입 이유**: 하드웨어 가속을 활용해 비디오를 인코딩/디코딩함으로써 CPU 부하와 기기 발열을 최소화하고, 고해상도 영상을 매끄럽게 처리하기 위해 선택했습니다.
    - **활용**: H.264 코덱을 사용하여 실시간 비디오 스트림을 압축하고 전송함으로써 네트워크 대역폭 효율을 높이고 지연 시간을 최소화합니다.

### 🎮 게임 엔진 및 AR
- **SpriteKit & ARKit**
    - **도입 이유**: 현실 세계와 상호작용하는 증강현실(AR) 환경을 구축하고, 2D 그래픽 요소를 가볍고 직관적으로 렌더링하기 위해 두 프레임워크를 함께 사용했습니다.
    - **활용**: `ARKit`의 Face Tracking 기술로 사용자의 표정과 움직임을 추적해 실시간 게임 컨트롤러로 변환하며, `SpriteKit` 기반의 물리 엔진과 애니메이션으로 몰입감 있는 게임 경험을 제공합니다.

### 🏗 프로젝트 관리 및 자동화
- **Tuist**
    - **도입 이유**: Xcode 프로젝트 파일(`.xcodeproj`)의 충돌을 방지하고, 모듈형 아키텍처를 효율적으로 관리하기 위해 도입했습니다.
    - **활용**: `Project.swift` 정의를 통해 여러 모듈(NetworkKit, VideoKit, Games 등) 간의 의존성을 체계적으로 관리하고 팀원 간 일관된 개발 환경을 유지합니다.
- **Fastlane**
    - **도입 이유**: 빌드, 테스트, 배포 과정을 자동화하여 개발 효율성을 높이고 반복적인 실수를 방지하기 위해 도입했습니다.
    - **활용**: `Match`를 통한 인증서 관리와 TestFlight 업로드 프로세스를 자동화하여 지속적인 배포(CD) 환경을 구축했습니다.


## 프로젝트 진행 방식
코스믹 어드벤처는 “완성도를 빠르게 끌어올리되, 리스크는 작게” 가져가는 방식으로 진행했습니다.  
아래 3가지를 중심으로 개발 프로세스를 설계하고 운영했습니다.

### 1) 피드백 반영한 점진적 개선 (Iterative Improvement)

<img width="300" alt="스크린샷 2026-02-01 오후 10 39 15" src="https://github.com/user-attachments/assets/f5523f18-6d55-4e61-b512-541e3fb30a67" />

저희는 **TestFlight/데모 피드백 루프**를 짧게 가져가며, 작은 단위로 배포→관찰→개선을 반복했습니다.  
특히 AR 입력/멀티플레이처럼 튜닝이 중요한 영역은 **체감 품질(오작동·지연·몰입감)** 기준으로 우선순위를 조정했습니다.

#### A. 플레이 버그 피드백 → 룰/카메라/물리 안정화
- **피드백**: “오프라인/근거리” 중심으로 설명했지만, 서비스 경험을 **근거리로만 제한할 필요는 없겠다**는 의견이 있었습니다.  
- **개선**: 메시지를 **‘어디서나/어느 환경에서나 함께’** 로 확장하고,  
  인터넷이 되는 환경에서는 **서버 기반 채널 매칭으로 장거리 플레이**,  
  불안정/단절 환경에서는 **근거리 P2P로 즉시 연결**이 가능하도록 방향을 정리했습니다.  

#### B. UX 피드백 → 이탈 포인트 제거

- **피드백**: 플레이 중 화면 자동 꺼짐(화면보호기능), 동료 선택 해제, 사용법 안내(다시보지 않기),
  키보드 포커스 해제, PIP 크기/위치, 캠/점수 레이아웃, 가로모드, “더 먼 은하” 네이밍/뒤로가기 혼란,
  권한 재요청 등이 불편 요소로 나왔습니다.  
  
- **개선**: 게임 흐름을 직접 끊는 이슈(권한/회전, 흐름/네이밍)를 **우선순위 상단**으로 두고,
  선택/입력/안내 UX를 묶어 **멈칫하는 지점**을 순차적으로 제거했습니다.  
  > [#92](https://github.com/boostcampwm2025/ios05-cosmic-adventure/pull/92)
  > [#97](https://github.com/boostcampwm2025/ios05-cosmic-adventure/pull/97)
  > [#148](https://github.com/boostcampwm2025/ios05-cosmic-adventure/pull/148)

#### C. 초대 수신 경험 개선(싱글 플레이 중)
- **피드백**: 알림 버튼을 눌러 확인하는 방식은 게임 중 초대를 놓치기 쉽다는 의견이 있었습니다.
- **개선**: 싱글 플레이 도중에도 초대를 즉시 인지하고 처리할 수 있도록 **Local Notification + 인앱 Top Modal** 방향을 검토/적용했습니다.  
  > PR: [#168](https://github.com/boostcampwm2025/ios05-cosmic-adventure/pull/168)

### 2) 태스크 관리 및 분배 (Task Management & Ownership)
  <img width="800" alt="스크린샷 2026-02-01 오후 11 26 07" src="https://github.com/user-attachments/assets/7ce9d547-ca69-4439-b026-de87fedcb9b9" />
  
- **Linear 기반 이슈 트래킹**으로 작업을 쪼개고, 각 태스크에 **담당자(Owner)와 완료 조건(DoD)** 을 명확히 정의했습니다.
- 프로젝트 시작 전, 기술 경험을 빠르게 맞추기 위해 **PoC 전용 브랜치**를 운영했습니다.  
  팀원들이 `SpriteKit / Network.framework / Video(H.264)` 핵심 영역을 각각 **프로토타입으로 구현**해보고,
  이후 본 개발에 들어갈 수 있도록 공통 이해도를 확보했습니다.
- 본 개발 단계에서는 모듈 구조(App / GameEngineCore / Games / InputSystem / NetworkKit / StorageKit / VideoKit`)에 맞춰  
  **경계가 깨지지 않도록** 태스크를 분배해 병렬 개발 효율을 높였습니다.
- 또한 특정 사람에게 지식이 쏠리지 않도록, 팀원 모두가 각 모듈을 이해할 수 있게  
  **담당하지 않았던 영역도 번갈아가며 개선/수정**하는 방식으로 운영했습니다(버스 팩터 감소).
- PR은 “리뷰 가능한 크기”를 유지하고, 병합 후에는 변경 영향 범위를 공유해 **리그레션을 최소화**했습니다.

### 3) AI 코드 리뷰 도입 (CodeRabbit)
<img width="500" alt="image" src="https://github.com/user-attachments/assets/eff98cc3-6ba7-4b7b-a879-2e66d489b832" />

- 반복적으로 놓치기 쉬운 부분(네이밍/문서화/컨벤션/잠재 버그)을 보완하기 위해  
  **CodeRabbit 기반 AI 코드 리뷰**를 CI 흐름에 포함했습니다.
- 사람 리뷰는 설계/경계/의도(Why) 중심으로, AI 리뷰는 **세부 품질(일관성/안전성/누락)**을 보조하는 방식으로 역할을 분리했습니다.

#### 리뷰 운영 방식 (P1 / P2)
- 사람 리뷰 코멘트는 **P1 / P2**로 분리해 기록했습니다.
  - **P1**: 꼭 수정이 필요한 사항(버그 가능성, 설계/경계 위반, 안정성/동시성 이슈 등)
  - **P2**: 사소하지만 개선하면 좋은 사항(스타일, 네이밍, 주석/문서화, 미세한 리팩터링 등)
- 반영 방식도 구분했습니다.
  - **P1 수정은 별도 커밋으로 남겨** 변경 의도와 영향을 명확히 추적 가능하게 했습니다.
  - **P2는 기존 커밋을 정리(reword/fixup)하는 방식**으로 히스토리를 깔끔하게 유지했습니다.

#### CodeRabbit 도입 효과
<img width="500" alt="image" src="https://github.com/user-attachments/assets/deddf168-8391-4cd1-9e42-722dd52a3222" />

- PR에서 놓치기 쉬운 **문서/네이밍/컨벤션 누락**을 자동으로 잡아줘, 기본 품질을 안정적으로 끌어올렸습니다.
- 동시성/안전성 관점의 **잠재 리스크를 조기에 발견**해, 수정 비용이 낮을 때 빠르게 대응할 수 있었습니다.
- 사람 리뷰는 “중요한 논점(P1)”에 집중하고, AI가 “자잘한 품질(P2)”을 보조하면서  
  **리뷰 속도와 밀도**가 함께 좋아졌고, 반복 피드백(컨벤션/스타일)의 커뮤니케이션 비용이 줄었습니다.

> 결과적으로, PR 당 리뷰 사이클이 더 예측 가능해졌고, 품질 기준을 팀 전체에 일관되게 적용할 수 있었습니다.


## 프로젝트 구조
### 폴더 구조
```swift
├── iOS/
│   ├── App/
│   │   ├── Sources/
│   │   ├── Resources/
│   │   └── Tests/
│   ├── Modules/
│   │   ├── GameEngineCore/
│   │   ├── InputSystem/
│   │   ├── NetworkKit/
│   │   ├── VideoKit/
│   │   ├── StorageKit/
│   │   └── Games/
│   └── Tuist/
├── backend/
│   ├── Sources/
│   ├── Tests/
│   └── Public/
├── fastlane/
├── docs/
├── Project.swift
└── cosmic-adventure.xcworkspace
```

### 모듈화
<img width="1607" height="796" alt="스크린샷 2026-02-01 오후 10 46 06" src="https://github.com/user-attachments/assets/1231c2bd-e2cb-4043-bc13-2fe42583f230" />
<br/>

### 모듈화 도입 이유 및 설계 원칙

> 고도화된 게임 경험과 유지보수의 효율성을 극대화하기 위해 **구조를 모듈화** 하였습니다. 그리고 단순히 코드를 나누는 것을 넘어, **SOLID 원칙**을 기반으로 지속 가능한 확장성을 확보하는 데 초점을 맞추었습니다

- **`SRP` (Single Responsibility Principle)**: 각 모듈은 물리 엔진, 네트워크, UI 등 독립적인 하나의 책임만을 수행하여 코드의 응집도를 높였습니다.
- **`DIP` (Dependency Inversion Principle)**: 상위 모듈은 하위의 구체 기술이 아닌 **Protocol** 에 의존합니다. 이를 통해 다른 모듈의 수정 없이 유연하게 대응합니다.
- **`OCP` (Open-Closed Principle)**: 기존 코드를 수정하지 않고 프로토콜 확장을 통해 기능을 더할 수 있는 구조를 구축하였습니다.

### 모듈별 역할

### **Application & UI**

- **`App`**: 프로젝트의 진입점으로, 전체 앱의 생명주기와 전역 설정을 관리합니다.
- **`Presentation`**: SwiftUI 기반의 UI와 ViewModel을 포함하며, 상태 관리와 모듈 간의 의존성을 주입(DI)하는 역할을 수행합니다.

### **Domain (Business Logic)**

- **`Domain`**: 게임의 규칙 및 핵심 비즈니스 로직을 포함합니다. 특정 기술 스택에 종속되지 않는 순수 로직으로 유지됩니다.
- **`Games`**: 게임의 구체적인 룰을 정의하는 모듈입니다.

### **Infrastructure (구체 기술 구현)**

- **`InputSystem`**: ARKit 기반의 얼굴 표정 트래킹 및 입력 이벤트를 처리하여 실시간 상호작용의 기반을 마련합니다.
- **`GameEngineCore`**: 게임 물리 연산 및 엔진의 핵심 기능을 담당하여 안정적인 게임 환경을 제공합니다.
- **`NetworkKit`**: P2P(Local) 및 WebSocket(Remote) 통신을 추상화하여 멀티플레이 환경을 구축합니다.
- **`VideoKit`**: 영상 데이터의 고효율 인코딩/디코딩 및 실시간 전송을 최적화합니다.
- **`StorageKit`**: SwiftData를 활용한 로컬 데이터 영속성 관리를 담당하며 정형화된 데이터 저장 구조를 제공합니다.


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

