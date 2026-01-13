.PHONY: setup ios ios-setup backend generate migrate db-reset test clean

# 초기 설정: iOS 프로젝트 생성 + DB 마이그레이션
setup:
	@$(MAKE) ios-setup
	@$(MAKE) migrate

# iOS 앱 실행
ios:
	@cd iOS && tuist run iOS

# iOS 프로젝트 생성/갱신
ios-setup:
	@cd iOS && tuist install && tuist generate

# 백엔드 서버 실행
backend:
	@cd backend && swift run App serve --hostname 0.0.0.0 --port 8080

# 마이그레이션 파일 생성
# 사용법: make generate → 이름 입력 → MigrationRegistry.swift에 등록 → make migrate
generate:
	@read -p "Migration name (snake_case): " name; \
	timestamp=$$(date +%Y%m%d%H); \
	filename="$${timestamp}_$${name}.swift"; \
	classname=$$(echo "$$name" | perl -pe 's/(^|_)(\w)/\U$$2/g'); \
	printf "import Fluent\n\nstruct %s: TimestampedMigration {\n    static let timestamp = %s\n\n    func prepare(on database: any Database) async throws {\n    }\n\n    func revert(on database: any Database) async throws {\n    }\n}\n" "$$classname" "$$timestamp" > backend/Sources/App/Migrations/$$filename; \
	echo "Created: backend/Sources/App/Migrations/$$filename"; \
	echo "Next: Register in MigrationRegistry.swift, then run 'make migrate'"

# DB에 마이그레이션 적용
migrate:
	@cd backend && swift run App migrate --yes

# DB 초기화 (삭제 후 재적용)
db-reset:
	@rm -f backend/db.sqlite
	@$(MAKE) migrate

# 테스트 실행
test:
	@cd backend && swift test

# 정리
clean:
	@cd iOS && tuist clean
	@cd backend && swift package clean
	@rm -f backend/db.sqlite

# 모듈생성
module:
	@read -p "생성할 모듈 이름을 입력하세요: " name; \
	cd iOS && tuist scaffold Modules --name $$name; \
	echo "✅ $$name 모듈이 생성되었습니다. Tuist 설정을 편집합니다..."; \
	tuist edit
