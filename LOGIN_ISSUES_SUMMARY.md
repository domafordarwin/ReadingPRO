# 로그인 시스템 문제 해결 요약 (2026-02-04)

## 🎯 해결 완료된 문제들

### 1. Turbo AJAX 422 에러 ✅
- **문제**: Turbo가 폼을 AJAX로 변환 → 422 응답 시 에러 메시지 표시 안됨
- **해결**: `data-turbo="false"` + `turbo:before-fetch-request` 이벤트 차단
- **파일**: `app/views/sessions/new.html.erb`

### 2. 무한 리다이렉트 루프 ✅
- **문제**: 세션 데이터가 남아있어 로그인 → 대시보드 → 권한 실패 → 로그인 무한 반복
- **해결**: `require_role_any`에서 세션 검증 후 `reset_session`
- **파일**: `app/controllers/application_controller.rb`, `app/controllers/sessions_controller.rb`

### 3. 비밀번호 인증 실패 ✅
- **문제**: 비밀번호 설정 시 백슬래시 이스케이프(`\$`) 문제
- **해결**: 올바른 비밀번호 `ReadingPro$12#`로 재설정
- **명령**: `pwd = 'ReadingPro' + '$' + '12#'`

---

## ⚠️ 현재 남아있는 문제들

### 문제 A: 교사 계정 대시보드 연결 안됨
**증상**:
- school_admin, diagnostic_teacher, teacher 계정 로그인 후 대시보드로 이동하지 않음
- 다른 계정 (student, parent, researcher, admin)은 정상 작동

**가능한 원인**:
1. Dashboard controller의 `before_action`에서 권한 체크 실패
2. `current_role` 메서드가 세션 데이터를 제대로 읽지 못함
3. `role_redirect_path`가 올바른 경로를 반환하지 않음

**확인 필요**:
```ruby
# 1. 세션 데이터 확인
session[:user_id]  # User ID가 있는가?
session[:role]     # Role이 올바른가?

# 2. current_role 확인
current_user&.role || session[:role]  # 무엇을 반환하는가?

# 3. 권한 체크 확인
require_role_any(%w[diagnostic_teacher teacher])  # 통과하는가?
```

**디버깅 코드 추가됨**:
- `app/controllers/sessions_controller.rb:44-47` - 로그인 시도 디버그 로깅
- `app/controllers/application_controller.rb:35,53` - 권한 거부 디버그 로깅

### 문제 B: 로그아웃 기능 작동 안함
**증상**:
- 로그아웃 버튼 클릭 시 로그아웃되지 않음

**확인 필요**:
1. 로그아웃 버튼이 올바르게 렌더링되는가?
   - `app/views/shared/_unified_header.html.erb:86`
   - `button_to "로그아웃", logout_path, method: :delete`

2. 로그아웃 라우트가 존재하는가?
   - ✅ `DELETE /logout → sessions#destroy`

3. Turbo가 DELETE 요청을 방해하는가?
   - `button_to`는 기본적으로 폼을 생성
   - Turbo가 이를 인터셉트할 가능성

**가능한 해결책**:
```erb
<!-- 방법 1: data-turbo 속성 추가 -->
<%= button_to "로그아웃", logout_path, method: :delete,
    data: { turbo: false },
    class: "rp-btn rp-btn--secondary rp-btn--sm" %>

<!-- 방법 2: link_to with data-method -->
<%= link_to "로그아웃", logout_path,
    data: { turbo_method: :delete },
    class: "rp-btn rp-btn--secondary rp-btn--sm" %>
```

---

## 🧪 테스트 체크리스트

### 즉시 수행 가능한 테스트

#### 1. 교사 계정 로그인 테스트
```bash
# 브라우저에서:
1. http://localhost:3000/login 접속
2. 이메일: school_admin@shinmyung.edu
3. 비밀번호: ReadingPro$12#
4. 로그인 버튼 클릭

# 예상 결과:
✅ 성공: /school_admin/dashboard로 리다이렉트
❌ 실패: 로그인 페이지로 돌아옴 또는 권한 에러
```

#### 2. 학생 계정 로그아웃 테스트
```bash
# 브라우저에서:
1. 학생 계정으로 로그인
2. 대시보드에서 "로그아웃" 버튼 클릭

# 예상 결과:
✅ 성공: /login으로 리다이렉트, "로그아웃되었습니다" 메시지
❌ 실패: 아무 일도 일어나지 않음
```

#### 3. Rails 로그 확인
```bash
# PowerShell에서:
cd "c:\WorkSpace\Project\2026_project\ReadingPro_Railway"
Get-Content log\development.log -Tail 50 -Wait

# 로그인 시도 시 다음을 확인:
# - "🔍 Login attempt - Email: ..."
# - "✅ User logged in: ..."
# - "❌ Access denied: ..."
```

---

## 🔧 긴급 수정 사항

### Fix 1: 로그아웃 버튼 Turbo 차단

**파일**: `app/views/shared/_unified_header.html.erb`
**라인**: 86

**수정 전**:
```erb
<%= button_to "로그아웃", logout_path, method: :delete, class: "rp-btn rp-btn--secondary rp-btn--sm" rescue link_to("로그아웃", "#", class: "rp-btn rp-btn--secondary rp-btn--sm") %>
```

**수정 후**:
```erb
<%= button_to "로그아웃", logout_path, method: :delete,
    data: { turbo: false },
    form: { data: { turbo: false } },
    class: "rp-btn rp-btn--secondary rp-btn--sm" %>
```

### Fix 2: 교사 대시보드 디버깅 로그 추가

**파일**: `app/controllers/diagnostic_teacher/dashboard_controller.rb`
**위치**: `index` 액션 시작 부분

**추가 코드**:
```ruby
def index
  Rails.logger.info "🎯 DiagnosticTeacher Dashboard accessed"
  Rails.logger.info "🔍 Current user: #{current_user&.id}, Role: #{current_role}"
  Rails.logger.info "🔍 Session: user_id=#{session[:user_id]}, role=#{session[:role]}"

  @current_page = "dashboard"
  # ... 나머지 코드
end
```

---

## 📝 다음 단계

1. **즉시 테스트**:
   - [ ] 학생 계정 로그인 → 로그아웃 버튼 클릭 → 작동 확인
   - [ ] 교사 계정 로그인 → 대시보드 이동 확인
   - [ ] Rails 로그 확인

2. **문제 발생 시**:
   - [ ] 브라우저 개발자 도구 (F12) 열기
   - [ ] Console 탭에서 JavaScript 에러 확인
   - [ ] Network 탭에서 로그아웃/로그인 요청 확인
   - [ ] Rails log에서 상세 로그 확인

3. **문서화**:
   - [ ] 테스트 결과를 이 파일에 업데이트
   - [ ] 해결된 문제는 CLAUDE.md에 기록

---

## 🚨 긴급 롤백 절차

문제가 악화되면 이전 커밋으로 롤백:

```bash
# 1. 현재 상태 확인
git status
git log --oneline -5

# 2. 특정 파일만 롤백
git checkout HEAD~1 app/controllers/application_controller.rb
git checkout HEAD~1 app/controllers/sessions_controller.rb

# 3. 서버 재시작
# Ctrl+C로 서버 종료
bin/rails server
```

---

## 📞 지원

**프로젝트**: ReadingPRO Railway
**환경**: Rails 8.1 + PostgreSQL
**마지막 업데이트**: 2026-02-04 01:32 KST

**테스트 계정 (모두 비밀번호: `ReadingPro$12#`)**:
- student_54@shinmyung.edu (학생)
- parent_54@shinmyung.edu (학부모)
- school_admin@shinmyung.edu (학교관리자)
- teacher_diagnostic@shinmyung.edu (진단교사)
- researcher@shinmyung.edu (문항개발)
- admin@readingpro.kr (시스템관리자)
