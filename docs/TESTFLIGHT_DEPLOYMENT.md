# TestFlight 자동 배포 가이드

## 개요

이 문서는 GitHub Actions와 Fastlane을 사용한 TestFlight 자동 배포 파이프라인에 대해 설명합니다.

### 워크플로우 요약

1. `ios-v*` 형식의 태그 푸시 시 자동 트리거
2. Tuist로 프로젝트 생성
3. Fastlane으로 빌드 및 TestFlight 업로드

---

## Fastlane Match 설정 (팀 권장)

### Match란?

Fastlane Match는 인증서와 프로비저닝 프로파일을 AWS S3에 암호화하여 저장하고, 팀원들이 안전하게 공유하는 방식입니다.

**장점:**
- 인증서/프로파일을 팀 전체가 공유
- 새 팀원 온보딩 시 간단한 명령어 하나로 설정 완료
- CI/CD에서도 동일한 방식으로 사용

### 배포 담당자 정보

| 항목 | 값 |
|------|-----|
| Apple ID | `rjwlehlwk@naver.com` |
| 역할 | Account Holder (개인 유료 계정) |
| Team ID | **확인 필요** (아래 가이드 참조) |

### 사전 준비 상태

| 항목 | 상태 | 값 |
|------|------|-----|
| AWS S3 버킷 | ✅ 완료 | `ios-certificates-cosmic` (ap-northeast-2) |
| Matchfile | ✅ 완료 | `fastlane/Matchfile` |
| Fastfile | ✅ 완료 | Match 연동 코드 추가됨 |
| 인증서 생성 | ⏳ 대기 | 아래 가이드 실행 필요 |

---

### 배포 담당자 (rjwlehlwk@naver.com) 실행 가이드

#### Step 1: Team ID 확인

1. [Apple Developer Portal](https://developer.apple.com/account) 접속
2. 로그인 후 **Membership** 메뉴 클릭
3. **Team ID** 확인 (10자리 영문+숫자)

```
예시: ABCD1234EF
```

#### Step 2: App ID (Bundle ID) 등록

1. [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) 접속
2. **Identifiers** → **+** 버튼 클릭
3. **App IDs** 선택 → **Continue**
4. **App** 선택 → **Continue**
5. 정보 입력:
   - **Description**: `Cosmic Adventure`
   - **Bundle ID**: `Explicit` 선택
   - **Bundle ID 값**: `kr.boostcamp10.ios05.cosmic-adventure`
6. **Continue** → **Register**

> ⚠️ Bundle ID가 이미 다른 계정에 등록되어 있으면 사용 불가. 이 경우 새 Bundle ID 필요.

#### Step 3: 환경변수 설정

터미널에서 실행 (Team ID를 Step 1에서 확인한 값으로 변경):

```bash
# AWS S3 접근용
export AWS_ACCESS_KEY_ID="[팀에서 공유받은 AWS Access Key]"
export AWS_SECRET_ACCESS_KEY="[팀에서 공유받은 AWS Secret Key]"

# Match 암호화 비밀번호 (팀 공유용으로 기억하기 쉬운 것 설정)
export MATCH_PASSWORD="[새로 설정할 암호화 비밀번호]"

# Team ID (Step 1에서 확인한 값)
export COSMIC_TEAM_ID="[YOUR_TEAM_ID]"
```

#### Step 4: Match 실행

프로젝트 폴더에서 실행:

```bash
cd /path/to/ios05-cosmic-adventure
/opt/homebrew/opt/ruby/bin/bundle exec fastlane match appstore
```

#### Step 5: Apple 인증

- Apple ID (`rjwlehlwk@naver.com`) 로그인
- 2FA 인증 코드 입력

#### Step 6: 완료 확인

다음 메시지가 나오면 성공:

```
All required keys, certificates and provisioning profiles are installed
```

#### Step 7: Team ID 코드에 반영 (선택)

Match 실행 후, Matchfile과 Appfile의 `YOUR_TEAM_ID`를 실제 값으로 변경:

```bash
# fastlane/Matchfile, fastlane/Appfile 수정
# team_id(ENV["COSMIC_TEAM_ID"] || "YOUR_TEAM_ID")
# → team_id(ENV["COSMIC_TEAM_ID"] || "ABCD1234EF")  # 실제 Team ID로 변경
```

---

### Match 실행 후 (다른 팀원용)

배포 담당자가 Match를 실행한 후, 다른 팀원들은 `--readonly` 모드로 사용:

```bash
# 환경변수 설정 (배포 담당자에게 공유받기)
export AWS_ACCESS_KEY_ID="[팀 공유 AWS Access Key]"
export AWS_SECRET_ACCESS_KEY="[팀 공유 AWS Secret Key]"
export MATCH_PASSWORD="[팀 공유 비밀번호]"
export COSMIC_TEAM_ID="[팀 공유 Team ID]"

# readonly 모드로 실행 (인증서 생성 권한 불필요)
/opt/homebrew/opt/ruby/bin/bundle exec fastlane match appstore --readonly
```

---

### GitHub Actions Secrets 설정

Match 방식 사용 시 필요한 GitHub Secrets:

**경로**: Repository → Settings → Secrets and variables → Actions

| Secret 이름 | 설명 | 누가 제공? |
|------------|------|-----------|
| `COSMIC_TEAM_ID` | Apple Developer Team ID | 배포 담당자 |
| `AWS_ACCESS_KEY_ID` | AWS Access Key | 기존 설정됨 |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | 기존 설정됨 |
| `MATCH_PASSWORD` | Match 암호화 비밀번호 | 배포 담당자 |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | API Key ID (10자) | 배포 담당자 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID (UUID) | 배포 담당자 |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | .p8 파일 Base64 | 배포 담당자 |

> App Store Connect API Key는 배포 담당자의 App Store Connect에서 생성 필요

---

### 현재 상태 체크리스트

```
[✅] AWS S3 버킷 생성 완료
[✅] Matchfile 설정 완료 (username: rjwlehlwk@naver.com)
[✅] Fastfile Match 연동 완료
[⏳] 배포 담당자 Team ID 확인 ← 여기!
[⏳] 배포 담당자 App ID 등록
[⏳] 배포 담당자 Match 실행
[ ] Team ID 코드 반영
[ ] GitHub Secrets 업데이트
[ ] CI/CD 테스트
```

---

## 수동 설정 방식 (GitHub Secrets)

> 아래는 Match를 사용하지 않고 수동으로 인증서를 관리하는 방식입니다.

## 필수 GitHub Secrets

GitHub 저장소 설정에서 다음 8개의 Secrets를 추가해야 합니다.

**경로**: Repository → Settings → Secrets and variables → Actions → New repository secret

| Secret 이름 | 설명 | 획득 방법 |
|------------|------|----------|
| `XCCONFIG_CONTENT` | 환경 설정 파일 내용 | ✅ 이미 설정됨 |
| `CERTIFICATE_P12_BASE64` | 배포 인증서 (Base64) | 아래 참조 |
| `CERTIFICATE_PASSWORD` | .p12 내보내기 비밀번호 | 인증서 내보낼 때 설정한 비밀번호 |
| `PROVISIONING_PROFILE_BASE64` | App Store 프로비저닝 프로파일 (Base64) | 아래 참조 |
| `APP_STORE_PROVISIONING_PROFILE_NAME` | 프로비저닝 프로파일 이름 | 아래 참조 |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | API Key ID (10자) | 아래 참조 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID (UUID) | 아래 참조 |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | .p8 파일 (Base64) | 아래 참조 |

### Secret 획득 방법

#### 1. CERTIFICATE_P12_BASE64

배포용 인증서를 Keychain에서 내보내기:

```bash
# 1. Keychain Access 앱 열기
# 2. "Apple Distribution: [팀명]" 인증서 찾기
# 3. 우클릭 → "내보내기" → .p12 형식으로 저장
# 4. 비밀번호 설정 (CERTIFICATE_PASSWORD로 사용)

# 5. Base64 인코딩
base64 -i certificate.p12 | pbcopy
# 클립보드에 복사된 값을 GitHub Secret에 붙여넣기
```

#### 2. PROVISIONING_PROFILE_BASE64

App Store 배포용 프로비저닝 프로파일:

```bash
# 1. Apple Developer Portal 접속
# 2. Certificates, Identifiers & Profiles → Profiles
# 3. App Store 배포용 프로파일 다운로드 (.mobileprovision)

# 4. Base64 인코딩
base64 -i profile.mobileprovision | pbcopy
```

#### 3. APP_STORE_PROVISIONING_PROFILE_NAME

프로비저닝 프로파일의 정확한 이름:

```bash
# 프로파일 이름 추출
security cms -D -i profile.mobileprovision | plutil -extract Name raw -
```

#### 4. App Store Connect API Key

App Store Connect에서 API Key 생성:

1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. Users and Access → Integrations → App Store Connect API
3. "+" 버튼으로 새 키 생성 (Admin 권한 필요)
4. 생성된 정보 저장:
   - **Key ID**: 10자리 문자열 → `APP_STORE_CONNECT_API_KEY_KEY_ID`
   - **Issuer ID**: UUID 형식 → `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
   - **.p8 파일**: 다운로드 (한 번만 가능!)

```bash
# .p8 파일 Base64 인코딩
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
# → APP_STORE_CONNECT_API_KEY_P8_BASE64
```

---

## 배포 트리거 방법

### 태그 형식

```
ios-v{major}.{minor}.{patch}
```

예시: `ios-v1.0.0`, `ios-v1.2.3`, `ios-v2.0.0`

> **주의**: `v*` 태그는 백엔드 배포에 사용되므로 반드시 `ios-v*` 형식을 사용하세요.

### 배포 명령어

```bash
# 1. 최신 코드 확인
git checkout develop
git pull origin develop

# 2. 태그 생성 및 푸시
git tag ios-v1.0.0
git push origin ios-v1.0.0
```

### 워크플로우 확인

태그 푸시 후 GitHub Actions에서 워크플로우 실행 확인:
- Repository → Actions → "Deploy to TestFlight"

---

## 빌드 번호 규칙

### 공식

```
빌드 번호 = (GITHUB_RUN_NUMBER × 10) + GITHUB_RUN_ATTEMPT
```

### 예시

| Run Number | Attempt | 빌드 번호 |
|------------|---------|----------|
| 1 | 1 | 11 |
| 1 | 2 (재시도) | 12 |
| 42 | 1 | 421 |
| 42 | 3 (재시도) | 423 |

### 특징

- 항상 증가하는 고유한 빌드 번호 보장
- 워크플로우 재시도 시에도 충돌 없음
- App Store Connect 요구사항 충족 (이전 빌드보다 큰 번호)

---

## 트러블슈팅

### 인증서 관련 오류

**증상**: `No signing certificate "Apple Distribution" found`

**해결 방법**:
1. Keychain에서 올바른 Distribution 인증서 내보내기 확인
2. 인증서가 만료되지 않았는지 확인
3. `CERTIFICATE_P12_BASE64`가 올바르게 인코딩되었는지 확인

```bash
# 인증서 확인
echo "$CERTIFICATE_P12_BASE64" | base64 -d > test.p12
security import test.p12 -P "$CERTIFICATE_PASSWORD"
```

### 프로비저닝 프로파일 오류

**증상**: `No provisioning profile found`

**해결 방법**:
1. App Store 배포용 프로파일인지 확인 (Development 아님)
2. Bundle ID가 일치하는지 확인: `kr.boostcamp10.ios05.cosmic-adventure`
3. 프로파일이 만료되지 않았는지 확인
4. `APP_STORE_PROVISIONING_PROFILE_NAME`이 정확한지 확인

### API Key 오류

**증상**: `Invalid API key`

**해결 방법**:
1. Key ID가 정확히 10자인지 확인
2. Issuer ID가 UUID 형식인지 확인
3. .p8 파일이 완전히 인코딩되었는지 확인 (헤더/푸터 포함)

### 빌드 실패

**증상**: `xcodebuild failed`

**해결 방법**:
1. 로컬에서 먼저 테스트:
   ```bash
   tuist install
   tuist generate
   xcodebuild -workspace cosmic-adventure.xcworkspace -scheme App -configuration Release
   ```
2. `XCCONFIG_CONTENT` Secret이 올바른지 확인

### Tuist 관련 오류

**증상**: `tuist: command not found`

**해결 방법**:
- 워크플로우에서 mise를 통해 Tuist가 설치됩니다
- `.mise.toml` 파일에 Tuist 버전이 명시되어 있는지 확인

---

## 관련 파일

| 파일 | 설명 |
|-----|------|
| `fastlane/Fastfile` | Fastlane 레인 정의 (`upload_testflight`, `sync_certificates` 레인) |
| `fastlane/Appfile` | 앱 식별 정보 (Bundle ID, Team ID) |
| `fastlane/Matchfile` | Fastlane Match 설정 (AWS S3 저장소, Apple ID) |
| `.github/workflows/deploy-testflight.yml` | GitHub Actions 워크플로우 |
| `iOS/App/Project.swift` | Tuist 프로젝트 설정 (CI 코드 서명 설정 포함) |

---

## 프로젝트 정보

| 항목 | 값 |
|-----|---|
| Bundle ID | `kr.boostcamp10.ios05.cosmic-adventure` |
| Team ID | 환경변수 `COSMIC_TEAM_ID`로 설정 (배포 담당자 계정) |
| Apple ID | `rjwlehlwk@naver.com` (배포 담당자) |
| Workspace | `cosmic-adventure.xcworkspace` |
| Scheme | `App` |
| 배포 방식 | `app-store` |

---

## 워크플로우 단계 상세

1. **Checkout**: 코드 체크아웃
2. **mise 설정**: mise-action으로 도구 설치
3. **Tuist 설치**: `mise install tuist`
4. **Environment.xcconfig 생성**: Secret에서 환경 설정 파일 생성
5. **Ruby 의존성 설치**: `bundle install`
6. **인증서 가져오기**: 임시 Keychain에 배포 인증서 설치
7. **프로비저닝 프로파일 설치**: 표준 경로에 프로파일 복사
8. **API Key 디코딩**: App Store Connect API Key 설정
9. **빌드 및 업로드**: `fastlane upload_testflight` 실행
10. **정리**: 민감한 파일 및 임시 Keychain 삭제

---

## 참고 링크

- [Fastlane 공식 문서](https://docs.fastlane.tools/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/deployment/deploying-xcode-applications)
- [Tuist 공식 문서](https://docs.tuist.io/)
