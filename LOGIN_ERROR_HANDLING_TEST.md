# 로그인 에러 처리 테스트 가이드

## 자동 테스트 시나리오

### 1. 입력 검증 테스트
- [ ] **빈 이메일**: 이메일 필드를 비우고 제출
  - 예상: "이메일과 비밀번호를 모두 입력해주세요." 메시지
- [ ] **빈 비밀번호**: 비밀번호 필드를 비우고 제출
  - 예상: "이메일과 비밀번호를 모두 입력해주세요." 메시지

### 2. 인증 실패 테스트
- [ ] **존재하지 않는 이메일**: `nonexistent@test.com` 입력
  - 예상: "등록되지 않은 이메일입니다. 입력하신 이메일을 확인해주세요." 메시지
- [ ] **잘못된 비밀번호**: 올바른 이메일 + 잘못된 비밀번호
  - 예상: "비밀번호가 올바르지 않습니다." 메시지

### 3. 성공적인 로그인 테스트
각 역할별로 테스트:
- [ ] **학생**: `student_54@shinmyung.edu` / `ReadingPro$12#`
  - 예상: `/student/dashboard`로 리다이렉트
- [ ] **학부모**: `parent_54@shinmyung.edu` / `ReadingPro$12#`
  - 예상: `/parent/dashboard`로 리다이렉트
- [ ] **진단교사**: `teacher_diagnostic@shinmyung.edu` / `ReadingPro$12#`
  - 예상: `/diagnostic_teacher/dashboard`로 리다이렉트
- [ ] **학교관리자**: `school_admin@shinmyung.edu` / `ReadingPro$12#`
  - 예상: `/school_admin/dashboard`로 리다이렉트
- [ ] **문항개발**: `researcher@shinmyung.edu` / `ReadingPro$12#`
  - 예상: `/researcher/dashboard`로 리다이렉트
- [ ] **관리자**: `admin@readingpro.kr` / `ReadingPro$12#`
  - 예상: `/admin/system`로 리다이렉트

### 4. UX 테스트
- [ ] **이중 제출 방지**: 로그인 버튼을 빠르게 여러 번 클릭
  - 예상: 첫 클릭만 처리되고 버튼이 비활성화됨
- [ ] **로딩 상태**: 로그인 버튼 클릭 시
  - 예상: 버튼 텍스트 "로그인 중..." 표시, 비활성화
- [ ] **에러 메시지 애니메이션**: 잘못된 자격증명 입력
  - 예상: 에러 메시지가 슬라이드 다운 애니메이션과 함께 표시
- [ ] **테스트 계정 버튼**: 개발 환경에서 테스트 계정 버튼 클릭
  - 예상: 자동으로 폼이 채워지고 제출됨

### 5. Turbo 차단 테스트
- [ ] **브라우저 개발자 도구 열기**: Network 탭 확인
- [ ] **로그인 실패 시도**: 잘못된 자격증명 입력
  - 예상: AJAX 요청 없음, 표준 POST 요청만 발생
  - 예상: 콘솔에 "[LoginForm] Turbo fetch request prevented for login form" 로그
  - 예상: 422 상태 코드 응답, 페이지 재렌더링
- [ ] **Flash 메시지 표시**: 422 응답 후
  - 예상: 에러 메시지가 폼 위에 표시됨

### 6. 브라우저 호환성 테스트
- [ ] Chrome/Edge (최신 버전)
- [ ] Firefox (최신 버전)
- [ ] Safari (최신 버전)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

---

## 수동 테스트 체크리스트

### 기본 기능
- [ ] 로그인 페이지 접근 가능 (`/login`)
- [ ] 폼이 올바르게 렌더링됨
- [ ] 사용자 유형 드롭다운 작동
- [ ] 비밀번호 토글 버튼 작동 (👁️)
- [ ] Placeholder 텍스트가 사용자 유형에 따라 변경됨

### 에러 처리
- [ ] 네트워크 에러 시 적절한 메시지 표시
- [ ] 서버 500 에러 시 에러 페이지 표시
- [ ] 데이터베이스 연결 실패 시 처리

### 보안
- [ ] 비밀번호 필드가 `type="password"`로 마스킹됨
- [ ] CSRF 토큰이 폼에 포함됨
- [ ] SQL Injection 방어 (prepared statements 사용)
- [ ] XSS 방어 (Rails의 자동 이스케이프)

### 접근성
- [ ] 키보드만으로 폼 작성 및 제출 가능
- [ ] Tab 순서가 논리적임
- [ ] Label이 input과 올바르게 연결됨
- [ ] 에러 메시지를 스크린 리더가 읽을 수 있음

---

## 콘솔 로그 확인사항

### 정상 동작 시 로그
```
[LoginForm] Turbo fetch request prevented for login form
[LoginForm] Standard form submission (non-AJAX)
[LoginForm] Form submitting with standard POST request
```

### 에러 발생 시 로그
```
[LoginForm] Turbo fetch request prevented for login form
[LoginForm] Standard form submission (non-AJAX)
[LoginForm] Form submitting with standard POST request
[LoginForm] State reset after page re-render
```

### 이중 제출 시도 시 로그
```
[LoginForm] Form submitting with standard POST request
[LoginForm] Double submission prevented
```

---

## 서버 로그 확인사항

### 성공적인 로그인
```
✅ User logged in: student_54@shinmyung.edu (student)
```

### 실패한 로그인
```
❌ Failed login attempt: wrong@email.com
```

### 시드 데이터 자동 로드 (첫 부팅)
```
🌱 Auto-loading seed data on first login attempt...
✅ Seed data loaded successfully
```

---

## 알려진 제한사항

1. **이메일 형식 검증**: 클라이언트 측 검증만 있음 (서버 측 추가 권장)
2. **비밀번호 복잡도**: 현재 검증 없음 (신규 회원가입 시 추가 필요)
3. **계정 잠금**: 실패 시도 제한 기능 없음 (브루트포스 공격 방어 필요)
4. **2FA**: 2단계 인증 미구현
5. **세션 타임아웃**: 명시적 타임아웃 설정 없음

---

## 향후 개선 사항

### 우선순위: 높음
- [ ] Rate limiting (로그인 시도 횟수 제한)
- [ ] 계정 잠금 기능 (5회 실패 시)
- [ ] 비밀번호 찾기 / 재설정 기능
- [ ] 이메일 형식 서버 측 검증

### 우선순위: 중간
- [ ] 로그인 기록 저장 (IP, 시간, 성공/실패)
- [ ] 세션 타임아웃 설정 (30분)
- [ ] "로그인 상태 유지" 옵션 (Remember Me)
- [ ] 소셜 로그인 (Google, Naver, Kakao)

### 우선순위: 낮음
- [ ] 2단계 인증 (TOTP)
- [ ] 생체 인증 (WebAuthn)
- [ ] 로그인 알림 (새 디바이스 접속 시)
- [ ] 다크 모드 지원

---

## 롤백 절차

문제 발생 시 이전 버전으로 롤백:

```bash
# 1. 현재 변경사항 확인
git status

# 2. 특정 파일만 롤백 (sessions/new.html.erb)
git checkout HEAD~1 app/views/sessions/new.html.erb

# 3. 컨트롤러만 롤백 (sessions_controller.rb)
git checkout HEAD~1 app/controllers/sessions_controller.rb

# 4. 전체 롤백 (모든 변경사항)
git reset --hard HEAD~1

# 5. 서버 재시작
bin/rails server
```

---

## 긴급 연락처

- **개발자**: Claude Code Agent
- **프로젝트**: ReadingPRO Railway Deployment
- **Git Branch**: main
- **마지막 업데이트**: 2026-02-04
