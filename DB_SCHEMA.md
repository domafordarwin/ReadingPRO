# ReadingPRO Database Schema (v2.0)

## 1. 사용자 관리 (User Management)

### `users`
```
id, email, password_digest, role, created_at, updated_at
role: enum(student, teacher, researcher, admin, parent)
```

### `students`
```
id, user_id, school_id, student_number, name, grade, class,
created_at, updated_at
```

### `teachers`
```
id, user_id, school_id, department, position, name,
created_at, updated_at
```

### `parents`
```
id, user_id, name, phone, email, created_at, updated_at
```

### `schools`
```
id, name, region, district, created_at, updated_at
```

### `school_students` (다대다)
```
id, school_id, student_id, created_at, updated_at
```

---

## 2. 문항 관리 (Item Management)

### `items`
```
id, code, item_type, difficulty, category, tags(jsonb),
prompt, explanation, stimulus_id, rubric_id, status,
created_by(teacher_id), created_at, updated_at

item_type: enum(mcq, constructed)
difficulty: enum(easy, medium, hard)
status: enum(draft, active, archived)
category: string (카테고리)
tags: jsonb (태그 배열)
```

### `item_choices` (객관식 선택지)
```
id, item_id, choice_no, content, is_correct,
created_at, updated_at
```

### `reading_stimuli` (지문)
```
id, title, body, source, word_count, reading_level,
created_by(teacher_id), created_at, updated_at
```

### `item_rubrics` (구성 평가 기준)
```
id, item_id, name, description, created_at, updated_at
```

### `rubric_criteria` (기준 항목)
```
id, item_rubric_id, criterion_name, description, max_score,
created_at, updated_at
```

### `rubric_levels` (채점 레벨)
```
id, rubric_criterion_id, level, score, description,
created_at, updated_at
```

---

## 3. 진단 관리 (Diagnostic Management)

### `diagnostic_forms`
```
id, name, description, item_count, time_limit_minutes,
difficulty_distribution(jsonb), status, created_by(teacher_id),
created_at, updated_at

status: enum(draft, active, archived)
difficulty_distribution: {easy: 3, medium: 5, hard: 2}
```

### `diagnostic_form_items`
```
id, diagnostic_form_id, item_id, position, points,
section_title, created_at, updated_at
```

### `student_attempts` (학생 응시 기록)
```
id, student_id, diagnostic_form_id, status,
started_at, submitted_at, time_spent_seconds,
created_at, updated_at

status: enum(in_progress, completed, submitted)
```

### `responses` (학생 답변)
```
id, student_attempt_id, item_id, selected_choice_id, answer_text,
is_correct, auto_score, manual_score, feedback_id,
created_at, updated_at
```

---

## 4. 피드백 관리 (Feedback Management)

### `feedbacks`
```
id, response_id, feedback_type, content, score_override,
is_auto_generated, created_by(teacher_id),
created_at, updated_at

feedback_type: enum(auto, manual)
```

### `response_rubric_scores` (구성형 답변 점수)
```
id, response_id, rubric_criterion_id, level_score,
created_by(teacher_id), created_at, updated_at
```

---

## 5. 포트폴리오 & 리포트 (Portfolio & Reporting)

### `student_portfolios`
```
id, student_id, total_attempts, total_score, average_score,
improvement_trend(jsonb), last_updated_at,
created_at, updated_at
```

### `school_portfolios`
```
id, school_id, total_students, total_attempts,
average_score, difficulty_distribution(jsonb),
performance_by_category(jsonb), last_updated_at,
created_at, updated_at
```

### `attempt_reports`
```
id, student_attempt_id, total_score, max_score,
score_percentage, performance_level, strengths(jsonb),
weaknesses(jsonb), recommendations(jsonb),
generated_at, created_at, updated_at

performance_level: enum(advanced, proficient, developing, beginning)
```

---

## 6. 관리 (Administration)

### `announcements`
```
id, title, content, priority, published_by(teacher_id),
published_at, created_at, updated_at

priority: enum(low, medium, high)
```

### `audit_logs`
```
id, user_id, action, resource_type, resource_id, changes(jsonb),
created_at
```

---

## 인덱스 전략

### 자주 조회되는 쿼리
```
- students.user_id
- students.school_id
- items.difficulty
- items.category
- items.status
- diagnostic_form_items.diagnostic_form_id
- student_attempts.student_id
- student_attempts.diagnostic_form_id
- student_attempts.status
- responses.student_attempt_id
- responses.item_id
```

### 복합 인덱스
```
- (diagnostic_form_id, position) ON diagnostic_form_items
- (student_id, diagnostic_form_id) ON student_attempts
- (student_attempt_id, item_id) ON responses
- (school_id, student_id) ON school_students
```

---

## 마이그레이션 전략

1. **Phase 1**: 기본 구조 (users, students, items, diagnostic_forms)
2. **Phase 2**: 응시 & 답변 (student_attempts, responses)
3. **Phase 3**: 피드백 & 채점 (feedbacks, response_rubric_scores)
4. **Phase 4**: 포트폴리오 & 리포트 (portfolios, reports)
5. **Phase 5**: 관리 (announcements, audit_logs)

---

## 총 테이블 수: 28개

**이전:** 52개 모델 → **현재:** 28개 테이블 (46% 감소)
**핵심 기능만 집중**
