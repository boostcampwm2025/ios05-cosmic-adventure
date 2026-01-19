# 서버 배포 가이드

## 사전 요구사항

* Docker & Docker Compose 설치
* 서버 SSH 접속 가능
* GitHub 레포지토리 Secrets 설정 완료

---

## GitHub Secrets 설정

**Repository Settings → Secrets and variables → Actions**에서 추가:

| Secret            | 설명                                         |
| ----------------- | ------------------------------------------ |
| `SSH_HOST`        | 서버 공인 IP 또는 도메인                            |
| `SSH_USERNAME`    | SSH 접속 유저명 (예: `root`, `ubuntu`, `deploy`) |
| `SSH_PRIVATE_KEY` | SSH 개인키 전체 내용                              |

> 참고: GHCR을 **private**으로 운영하고 서버에서 `docker login ghcr.io`가 필요하면, 아래 Secrets도 추가하세요.
>
> | Secret          | 설명                                                |
> | --------------- | ------------------------------------------------- |
> | `GHCR_USERNAME` | GHCR pull 권한이 있는 GitHub 사용자명(또는 bot 계정)           |
> | `GHCR_TOKEN`    | GitHub Personal Access Token (`read:packages` 권한) |

---

## 서버 초기 설정

```bash
# 1) 배포 디렉토리 생성
sudo mkdir -p /srv/cosmic-adventure
sudo chown $USER:$USER /srv/cosmic-adventure
cd /srv/cosmic-adventure

# 2) 배포 파일 준비 (이 레포의 deploy/ 폴더에서 복사)
# - docker-compose.yml
# - nginx.conf

# 3) SQLite 영속 디렉토리 생성 (필수)
mkdir -p data

# 4) HTTPS용 인증서 디렉토리 생성 (선택)
mkdir -p certs

# 5) (선택) GHCR 로그인 (최초 1회)
# - GHCR 이미지가 public이면 생략 가능
# - private이면 GitHub PAT 필요 (read:packages 권한)
echo "YOUR_GITHUB_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# 6) 서비스 시작
docker compose up -d

# 7) 상태 확인
docker compose ps
docker compose logs -f
```

---

## 배포 흐름

1. `develop` 브랜치에 PR 생성 또는 push (`backend/` 변경 시)
2. GitHub Actions가 이미지 빌드 → GHCR에 푸시
3. `develop`에 merge되면 SSH로 서버에 자동 배포

---

## 자주 쓰는 명령어

```bash
# 로그 확인
docker compose logs -f backend
docker compose logs -f nginx

# 서비스 재시작
docker compose restart

# 수동 배포 (pull + 재시작)
docker compose pull && docker compose up -d

# 헬스체크 (서버 내부에서)
curl http://localhost/status
```

---

## 도메인 연결 & HTTPS(SSL) 적용 (NCP)

### 1) NCP Global DNS 설정

1. NCP 콘솔 → **Networking → Global DNS** 이동
2. 도메인 추가 (소유한 도메인 등록)
3. 레코드 추가:
   - `A` 레코드: `@` → 서버 공인 IP
   - `A` 레코드: `www` → 서버 공인 IP (선택)
4. 도메인 등록 업체에서 네임서버를 NCP로 변경

### 2) NCP Certificate Manager로 인증서 발급

1. NCP 콘솔 → **Security → Certificate Manager** 이동
2. **인증서 신청** 클릭
3. 도메인 입력 (예: `your-domain.com`)
4. DNS 검증 방식 선택 → Global DNS 사용 시 자동 검증 가능
5. 발급 완료 후 인증서 다운로드 (`.crt`, `.key` 파일)

### 3) 서버에 인증서 배치

```bash
cd /srv/cosmic-adventure
mkdir -p certs

# 다운로드한 인증서 파일 업로드
# - fullchain.crt (또는 certificate.crt + ca_bundle.crt 합친 파일)
# - private.key
```

### 4) docker-compose.yml 수정

`nginx` 서비스에 443 포트와 certs 볼륨 추가:

```yaml
nginx:
  image: nginx:alpine
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf:ro
    - ./certs:/etc/nginx/certs:ro
  depends_on:
    - backend
```

### 5) nginx.conf에 SSL 설정 추가

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/certs/fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/private.key;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
```

### 6) 적용

```bash
cd /srv/cosmic-adventure
docker compose down
docker compose up -d
```

---
