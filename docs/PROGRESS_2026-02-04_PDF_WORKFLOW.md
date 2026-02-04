# PDF 업로드 워크플로우 개선 작업

## 📅 날짜: 2026-02-04
## ⏰ 작업 시간: 저녁

---

## 🎯 작업 목표

PDF 업로드 후 사용자가 각 문항의 정답 및 채점 기준을 쉽게 설정할 수 있도록 워크플로우 개선

---

## ✅ 완료된 작업

### 1. 현황 분석
- ✅ 기존 PDF 업로드 기능 확인
  - `OpenaiPdfParserService`: GPT-4를 통한 PDF 구조 분석
  - `PdfItemParserService`: DB 레코드 생성
  - `upload_pdf` 액션: 파일 업로드 처리
- ✅ 문제점 파악:
  - 업로드 후 item_bank으로 리디렉션 → 어떤 문항을 편집해야 할지 불명확
  - 진단지 상세 페이지에서 정답 설정 상태 표시 없음
  - 정답이 모두 `is_correct: false`로 생성됨

### 2. PdfItemParserService 개선
**파일:** `app/services/pdf_item_parser_service.rb`

변경 사항:
```ruby
# @results에 stimulus_ids 추가
@results = {
  stimuli_created: 0,
  items_created: 0,
  errors: [],
  stimulus_ids: []  # 생성된 stimulus ID 추적
}

# create_stimulus 메서드에서 ID 추적
@results[:stimulus_ids] << stimulus.id
```

### 3. upload_pdf 액션 개선
**파일:** `app/controllers/researcher/dashboard_controller.rb:151-179`

변경 사항:
- 성공 시 생성된 진단지 상세 페이지로 리디렉션
- 사용자 친화적인 플래시 메시지 추가
```ruby
if results[:stimulus_ids].present?
  redirect_to researcher_passage_path(results[:stimulus_ids].first)
else
  redirect_to researcher_item_bank_path
end
```

### 4. 진단지 상세 페이지 개선
**파일:** `app/views/researcher/stimuli/show.html.erb`

#### 4.1 정답 미설정 배지 추가
- 객관식 문항: 정답이 없는 경우 "정답 미설정" 배지 표시
- 서술형 문항: 루브릭이 없거나 기본값만 있는 경우 "채점기준 미설정" 배지 표시

```erb
<% if item.item_type == 'mcq' %>
  <% if item.item_choices.none?(&:is_correct) %>
    <span class="answer-status-badge answer-missing">정답 미설정</span>
  <% end %>
<% elsif item.item_type == 'constructed' %>
  <% if item.rubric.blank? || item.rubric.rubric_criteria.count <= 1 %>
    <span class="answer-status-badge answer-missing">채점기준 미설정</span>
  <% end %>
<% end %>
```

#### 4.2 버튼 텍스트 동적 변경
- 정답/채점기준 미설정 시: "정답 설정" 또는 "채점기준 설정"
- 이미 설정된 경우: "편집"
- 미설정 버튼은 `action-btn-primary` 스타일로 강조

```erb
<%
  needs_answer_setup = false
  button_text = "편집"

  if item.item_type == 'mcq' && item.item_choices.none?(&:is_correct)
    needs_answer_setup = true
    button_text = "정답 설정"
  elsif item.item_type == 'constructed' && (item.rubric.blank? || item.rubric.rubric_criteria.count <= 1)
    needs_answer_setup = true
    button_text = "채점기준 설정"
  end
%>
<%= link_to edit_researcher_item_path(item),
    class: "action-btn action-btn-#{needs_answer_setup ? 'primary' : 'outline'} action-btn-xs" do %>
  ...
  <span><%= button_text %></span>
<% end %>
```

#### 4.3 배지 스타일 추가
```css
.answer-status-badge {
  font-size: 0.7rem;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
  font-weight: 600;
  animation: pulse-warning 2s ease-in-out infinite;
}

.answer-status-badge.answer-missing {
  background: #fef3c7;
  color: #d97706;
  border: 1px solid #fbbf24;
}

@keyframes pulse-warning {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}
```

### 5. 메모리 업데이트
**파일:** `C:\Users\domam\.claude\projects\c--WorkSpace-Project-2026-project-ReadingPro-Railway\memory\MEMORY.md`

- PDF 업로드 워크플로우 섹션 추가
- 주요 파일 위치 업데이트
- PDF 업로드 후 해야 할 작업 가이드 추가

---

## 📊 개선된 워크플로우

### 이전 워크플로우
1. PDF 업로드
2. 파싱 및 DB 생성
3. item_bank으로 리디렉션 ❌
4. 사용자가 수동으로 진단지 찾기 ❌
5. 각 문항 편집

### 개선된 워크플로우
1. PDF 업로드
2. 파싱 및 DB 생성
3. **생성된 진단지 상세 페이지로 자동 리디렉션** ✅
4. **정답 미설정 배지 및 강조된 버튼 표시** ✅
5. **"정답 설정" 또는 "채점기준 설정" 버튼 클릭** ✅
6. 정답/채점기준 입력 및 저장
7. 완료된 문항은 일반 "편집" 버튼으로 변경 ✅

---

## 🎨 사용자 경험 개선 사항

1. **명확한 안내:** 업로드 성공 메시지에 "각 문항의 정답과 채점 기준을 설정해주세요" 포함
2. **시각적 피드백:** 정답 미설정 문항에 펄스 애니메이션 배지
3. **직관적인 버튼:** 미설정 시 파란색 그라디언트 버튼으로 강조
4. **자동 네비게이션:** 생성된 진단지로 자동 이동

---

## 📝 변경된 파일 목록

1. `app/services/pdf_item_parser_service.rb`
   - stimulus_ids 추적 로직 추가

2. `app/controllers/researcher/dashboard_controller.rb`
   - upload_pdf 액션 개선 (리디렉션 로직)

3. `app/views/researcher/stimuli/show.html.erb`
   - 정답 미설정 배지 추가
   - 버튼 텍스트 동적 변경
   - 배지 스타일 추가

4. `C:\Users\domam\.claude\projects\c--WorkSpace-Project-2026-project-ReadingPro-Railway\memory\MEMORY.md`
   - PDF 업로드 워크플로우 문서화

---

## ✅ 테스트 체크리스트

- [ ] PDF 업로드 후 진단지 상세 페이지로 리디렉션
- [ ] 객관식 문항에 "정답 미설정" 배지 표시
- [ ] 서술형 문항에 "채점기준 미설정" 배지 표시
- [ ] "정답 설정" 버튼 클릭 시 문항 편집 페이지로 이동
- [ ] 정답 설정 후 배지 및 버튼 텍스트 변경
- [ ] 채점 기준 설정 후 배지 제거 확인

---

## 🔄 향후 개선 가능 사항

1. **배치 정답 설정:** 여러 문항의 정답을 한 번에 설정하는 UI
2. **AI 정답 추천:** GPT-4가 파싱 시 정답도 추론하여 제안
3. **진행률 표시:** 진단지 상세 페이지에 "3/5 문항 정답 설정 완료" 표시
4. **알림 시스템:** 정답 미설정 문항이 있는 진단지에 대한 알림

---

**작업 완료 시각:** 2026-02-04 저녁
**소요 시간:** 약 30분
**테스트 환경:** 개발 환경 (로컬)
