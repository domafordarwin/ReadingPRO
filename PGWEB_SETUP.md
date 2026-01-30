# pgweb PostgreSQL Web UI 설정 가이드

pgweb은 웹 브라우저에서 PostgreSQL 데이터베이스를 관리할 수 있는 도구입니다.

## 📦 설치

### macOS (Homebrew)
```bash
brew install pgweb
```

### Windows (Scoop)
```bash
scoop install pgweb
```

### 또는 직접 다운로드
https://sosedoff.com/pgweb/에서 다운로드

---

## 🚀 실행 방법

### 방법 1: Rails Task 사용 (권장)

#### 1. 데이터베이스 연결 정보 확인
```bash
bundle exec rails pgweb:info
```

#### 2. pgweb 시작
```bash
bundle exec rails pgweb:start
```

#### 3. 브라우저에서 접속
```
http://localhost:8081
```

---

### 방법 2: 환경 변수를 사용하여 직접 실행

#### 로컬 개발 환경
```bash
# 터미널에서 환경 변수 설정
export DATABASE_URL="postgres://postgres:password@localhost:5432/reading_pro_development"

# pgweb 시작
pgweb
```

#### Windows Command Prompt
```cmd
set DATABASE_URL=postgres://postgres:password@localhost:5432/reading_pro_development
pgweb
```

#### Windows PowerShell
```powershell
$env:DATABASE_URL = "postgres://postgres:password@localhost:5432/reading_pro_development"
pgweb
```

---

### 방법 3: Railway 배포 환경

#### 1. Railway CLI 설치
```bash
npm install -g railway
```

#### 2. Railway에 로그인하고 링크
```bash
railway login
railway link
```

#### 3. 데이터베이스 연결 정보 확인
```bash
railway service add
# PostgreSQL 선택
```

#### 4. DATABASE_URL 환경 변수 가져오기
```bash
railway env
```

#### 5. pgweb 시작
```bash
# 환경 변수를 설정하고 pgweb 실행
pgweb --url "$DATABASE_URL"
```

또는 Rails task 사용:
```bash
bundle exec rails pgweb:start
```

---

## 🛠️ 스크립트 파일

### Linux/macOS
```bash
./script/pgweb_connect.sh
```

### Windows
```cmd
script\pgweb_connect.bat
```

---

## 📊 데이터베이스 연결 정보 예시

### 로컬 개발
```
postgres://postgres:password@localhost:5432/reading_pro_development
```

- **Host**: localhost
- **Port**: 5432
- **Database**: reading_pro_development
- **Username**: postgres
- **Password**: (your password)

### Railway 배포
```
postgres://user:password@db.railway.internal:5432/railway
```

- **Host**: db.railway.internal
- **Port**: 5432
- **Database**: railway
- **Username**: (Railway 제공)
- **Password**: (Railway 제공)

---

## 🌐 웹 UI 접속

pgweb이 시작되면 자동으로 다음 주소에서 접속 가능합니다:
```
http://localhost:8081
```

### 주요 기능
- ✅ SQL 쿼리 실행
- ✅ 테이블 조회 및 편집
- ✅ 데이터 검색 및 필터링
- ✅ 데이터베이스 스키마 확인
- ✅ 백업 및 복원 (제한적)

---

## 🔧 문제 해결

### "pgweb command not found"
pgweb이 설치되지 않았거나 PATH에 추가되지 않았습니다.
```bash
# 설치 확인
which pgweb

# 또는 전체 경로로 실행
/usr/local/bin/pgweb --url "postgres://..."
```

### "DATABASE_URL not set"
DATABASE_URL 환경 변수를 설정해야 합니다.
```bash
# 확인
echo $DATABASE_URL

# 설정
export DATABASE_URL="postgres://user:password@host:port/database"
```

### "Connection refused"
데이터베이스 서버가 실행 중인지 확인하세요.
```bash
# PostgreSQL 서버 상태 확인 (macOS)
brew services list

# 또는 포트 확인
lsof -i :5432
```

### "FATAL: password authentication failed"
암호가 올바른지 확인하세요.
```bash
# psql을 사용하여 테스트
psql -U postgres -h localhost -d reading_pro_development
```

---

## 📝 참고

- [pgweb 공식 사이트](https://sosedoff.com/pgweb/)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [Railway 문서](https://docs.railway.app/)

---

## 🔐 보안 주의사항

- ⚠️ 프로덕션 환경에서 pgweb을 인터넷에 노출하지 마세요
- ⚠️ DATABASE_URL에 암호를 포함하면 history에 남을 수 있으니 주의하세요
- ⚠️ 로컬에서만 사용하거나 적절한 인증을 설정하세요

---

## 💡 추가 팁

### pgweb 포트 변경
```bash
pgweb --url "postgres://..." --listen 0.0.0.0:9000
```

### SSL 무시 (개발 환경)
```bash
pgweb --url "postgres://user:password@host:port/db?sslmode=disable"
```

### 여러 데이터베이스 동시 접속
각각 다른 포트로 실행:
```bash
pgweb --url "postgres://..." --listen 0.0.0.0:8081 &
pgweb --url "postgres://..." --listen 0.0.0.0:8082 &
```
