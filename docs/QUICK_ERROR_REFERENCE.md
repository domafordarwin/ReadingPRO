# Quick Error Reference

ReadingPRO 개발 시 자주 발생하는 에러와 즉시 해결 방법

## 1. NoMethodError: undefined method 'column_name'

```
NoMethodError: undefined method 'scoring_meta' for Item
```

**즉시 확인:**
```bash
rails runner "puts Item.column_names.inspect"
```

**해결:** 구 스키마 컬럼 → 신 스키마 컬럼 변경
- 상세 매핑: `docs/raw_data/development_history/SCHEMA_MIGRATION_2026_02_04.md`

## 2. PG::UndefinedColumn

```
PG::UndefinedColumn: ERROR: column "position" does not exist
```

**확인:**
```bash
rails runner "puts Model.column_names.inspect"
```

**해결:** `.order(:position)` → `.order(:id)` 등으로 변경

## 3. Turbo AJAX 422 Error

```
POST /login 422 Unprocessable Content
```

**해결:**
```erb
<%= form_with data: { turbo: false } do |f| %>
```

## 4. Nested Array Bug (교사 대시보드 접근 불가)

```ruby
# 로그: required_roles=[["school_admin", "teacher"]]
```

**해결:**
```ruby
def require_role_any(*roles)
  roles = roles.flatten  # 추가
  return if roles.include?(current_role)
end
```

## 5. Counter Cache N+1

```ruby
# Bad ❌
@items.each { |item| item.stimulus.items.count }

# Good ✅
@items.each { |item| item.stimulus.items_count }
```

## 6. Password Escaping

```ruby
# Bad ❌
TEST_PASSWORD = "ReadingPro\$12#"

# Good ✅
TEST_PASSWORD = "ReadingPro" + "$" + "12#"
```

## 7. Researcher Portal Missing Models

```
NoMethodError: undefined method 'each' for nil:NilClass
# @prompts 또는 @books가 nil인 경우
```

**해결:**
- Prompt/Book 모델이 아직 구현되지 않음
- 상세 내용: `docs/raw_data/development_history/RESEARCHER_PORTAL_MISSING_FEATURES_2026_02_04.md`

**현재 상태:**
- ✅ evaluation.html.erb: 동적 데이터 로드 (EvaluationIndicator)
- ❌ prompts.html.erb: Prompt 모델 필요
- ❌ books.html.erb: Book 모델 필요
- ✅ legacy_db.html.erb: 정적 페이지 (의도적)

## 빠른 체크리스트

- [ ] 스키마 확인: `rails runner "puts Model.column_names.inspect"`
- [ ] Counter cache 우선 사용
- [ ] Turbo 필요시 비활성화: `data: { turbo: false }`
- [ ] N+1 방지: `.includes()` 사용
- [ ] 배열 flatten: `roles.flatten` 추가
- [ ] 새 페이지 개발 전: 필요한 모델이 존재하는지 확인

## 상세 문서

자세한 내용은 다음 문서를 참조하세요:
- 스키마 마이그레이션: `docs/raw_data/development_history/SCHEMA_MIGRATION_2026_02_04.md`
- 로그인 이슈: `docs/raw_data/development_history/LOGIN_ISSUES_HISTORY_2026_02.md`
