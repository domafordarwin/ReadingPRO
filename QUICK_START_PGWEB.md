# pgweb 빠른 시작 가이드

## ⚡ 30초 시작하기

### 1단계: pgweb 설치
```bash
# macOS
brew install pgweb

# Windows (Scoop)
scoop install pgweb
```

### 2단계: 실행 (선택 하나)

#### 🎯 가장 간단한 방법 (Rails)
```bash
bundle exec rails pgweb:info
bundle exec rails pgweb:start
```

#### 또는 직접 실행
```bash
# 로컬 개발
export DATABASE_URL="postgres://postgres:password@localhost:5432/reading_pro_development"
pgweb

# Railway (환경 변수 자동 설정된 경우)
pgweb
```

### 3단계: 브라우저 접속
```
http://localhost:8081
```

---

## 📋 상황별 가이드

### 로컬 PostgreSQL 접속
```bash
# Step 1: 설정 확인
bundle exec rails pgweb:info

# Step 2: 시작
bundle exec rails pgweb:start
```

### Railway 프로덕션 DB 접속
```bash
# Step 1: Railway 환경 설정
railway link

# Step 2: pgweb 시작
bundle exec rails pgweb:start
```

### 커스텀 DATABASE_URL 사용
```bash
# 방법 1: 환경 변수 설정
export DATABASE_URL="postgres://user:password@host:port/db"
pgweb

# 방법 2: 인라인 실행
DATABASE_URL="postgres://user:password@host:port/db" pgweb

# 방법 3: Rails task
DATABASE_URL="postgres://..." bundle exec rails pgweb:start
```

---

## 🎮 웹 UI 사용법

pgweb 접속 후:

1. **왼쪽 사이드바**: 데이터베이스 선택
2. **테이블 목록**: 테이블 클릭하여 데이터 조회
3. **SQL 탭**: 직접 SQL 쿼리 작성 및 실행
4. **검색 기능**: 데이터 검색 및 필터링

---

## 🔗 연결 문자열 형식

```
postgres://[username[:password]@][host[:port]]/[database][?params]
```

**예시:**
```
postgres://postgres:password@localhost:5432/reading_pro_development
postgres://user@db.railway.internal:5432/railway?sslmode=require
postgres://localhost/mydb  # 암호 없음
```

---

## ✅ 체크리스트

- [ ] pgweb 설치됨 (`which pgweb` 확인)
- [ ] PostgreSQL 실행 중 (`lsof -i :5432` 확인)
- [ ] DATABASE_URL 설정됨
- [ ] `http://localhost:8081` 접속 가능
- [ ] 테이블 데이터 조회 성공

---

## 🆘 도움말

| 문제 | 해결책 |
|------|-------|
| pgweb이 설치되지 않음 | `brew install pgweb` |
| DATABASE_URL not found | `export DATABASE_URL="..."` |
| Connection refused | PostgreSQL 실행 확인: `brew services list` |
| 포트 8081이 사용 중 | `pgweb --listen 0.0.0.0:9000` |
| 암호 오류 | PASSWORD 확인: `psql -U postgres` |

---

## 📚 상세 가이드

[PGWEB_SETUP.md](PGWEB_SETUP.md)에서 전체 설명을 확인하세요.
