# 문항 은행 재설계 (Item Bank Redesign)

## 📋 작업 일자: 2026-02-04

## 🎯 목표
개별 문항이 아닌 **완성된 진단지 세트**를 문항 은행에 등록하고 관리

## 📊 현재 문제점

### 1. 스키마 문제
- `reading_stimuli`: 연결된 문항 코드 목록이 없음
- `items`: 지문 코드 참조가 없음 (stimulus_id만 있음)
- 진단지 세트 개념 없음

### 2. UI 문제
- 문항 은행이 개별 문항(Item) 카드를 표시
- 완성된 진단지 세트 정보가 아님

### 3. 업로드 로직 문제
- PDF 업로드 시 개별 문항만 생성
- 세트로 묶이지 않음

## 🏗️ 새로운 설계

### 데이터베이스 스키마 변경

#### ReadingStimulus 테이블 추가 컬럼
```ruby
# 지문 고유 코드
add_column :reading_stimuli, :code, :string, null: false
add_index :reading_stimuli, :code, unique: true

# 연결된 문항 코드 배열
add_column :reading_stimuli, :item_codes, :text, array: true, default: []
add_index :reading_stimuli, :item_codes, using: :gin

# 세트 메타데이터 (JSONB)
add_column :reading_stimuli, :bundle_metadata, :jsonb, default: {}
# bundle_metadata 구조:
# {
#   mcq_count: 2,              # 객관식 문항 개수
#   constructed_count: 1,       # 서술형 문항 개수
#   total_count: 3,             # 전체 문항 개수
#   key_concepts: ["적정기술", "물 정화"],  # 진단 핵심 요소
#   difficulty_distribution: { easy: 0, medium: 3, hard: 0 },
#   estimated_time_minutes: 15
# }

# 세트 상태
add_column :reading_stimuli, :bundle_status, :string, default: 'draft'
# draft: 작업중, active: 배포가능, archived: 폐기
```

#### Item 테이블 추가 컬럼
```ruby
# 지문 코드 참조 (선택적, 명시적 참조용)
add_column :items, :stimulus_code, :string
add_index :items, :stimulus_code
```

### 모델 관계

```ruby
class ReadingStimulus < ApplicationRecord
  # 기존 관계
  has_many :items, foreign_key: 'stimulus_id', dependent: :nullify

  # 새로운 validations
  validates :code, presence: true, uniqueness: true
  validates :bundle_status, inclusion: { in: %w[draft active archived] }

  # 메타데이터 계산
  def recalculate_bundle_metadata!
    items = Item.where(stimulus_id: id)

    self.bundle_metadata = {
      mcq_count: items.where(item_type: 'mcq').count,
      constructed_count: items.where(item_type: 'constructed').count,
      total_count: items.count,
      key_concepts: extract_key_concepts,
      difficulty_distribution: {
        easy: items.where(difficulty: 'easy').count,
        medium: items.where(difficulty: 'medium').count,
        hard: items.where(difficulty: 'hard').count
      },
      estimated_time_minutes: calculate_estimated_time(items)
    }

    self.item_codes = items.pluck(:code)
    save!
  end

  private

  def extract_key_concepts
    # AI 또는 규칙 기반 키워드 추출
    # 일단은 제목에서 추출
    return [] if title.blank?
    title.split(/[,\s-]+/).reject(&:blank?)
  end

  def calculate_estimated_time(items)
    # MCQ: 2분, Constructed: 5분
    mcq_time = items.where(item_type: 'mcq').count * 2
    constructed_time = items.where(item_type: 'constructed').count * 5
    mcq_time + constructed_time
  end
end

class Item < ApplicationRecord
  belongs_to :stimulus, class_name: 'ReadingStimulus', foreign_key: 'stimulus_id', optional: true

  # 코드 생성 콜백
  after_create :update_stimulus_item_codes
  after_destroy :update_stimulus_item_codes

  private

  def update_stimulus_item_codes
    return unless stimulus_id

    stimulus = ReadingStimulus.find_by(id: stimulus_id)
    stimulus&.recalculate_bundle_metadata!
  end
end
```

## 📁 PDF 업로드 워크플로우

### 1. PDF 업로드 → 파싱
```
사용자가 PDF 업로드
↓
OpenaiPdfParserService: PDF 텍스트 추출 + GPT-4 구조화
↓
반환 데이터:
{
  reading_stimuli: [{ title, body }],
  mcq_items: [{ code, prompt, choices, stimulus_index }],
  constructed_items: [{ code, prompt, stimulus_index }]
}
```

### 2. 데이터베이스 생성
```ruby
# PdfItemParserService.create_items_from_parsed_data

# 1. ReadingStimulus 생성
stimulus = ReadingStimulus.create!(
  code: generate_stimulus_code,  # "STIM_#{timestamp}_#{random}"
  title: data[:title],
  body: data[:body],
  bundle_status: 'draft'
)

# 2. Item 생성 (MCQ)
mcq_items = parsed_data[:mcq_items].map do |item_data|
  Item.create!(
    code: item_data[:code],
    item_type: 'mcq',
    prompt: item_data[:prompt],
    stimulus_id: stimulus.id,
    stimulus_code: stimulus.code,
    difficulty: 'medium',
    status: 'draft'
  )
  # ItemChoice도 생성
end

# 3. Item 생성 (Constructed)
constructed_items = parsed_data[:constructed_items].map do |item_data|
  Item.create!(
    code: item_data[:code],
    item_type: 'constructed',
    prompt: item_data[:prompt],
    stimulus_id: stimulus.id,
    stimulus_code: stimulus.code,
    difficulty: 'medium',
    status: 'draft'
  )
  # Rubric도 생성
end

# 4. Stimulus 메타데이터 업데이트
stimulus.recalculate_bundle_metadata!
```

### 3. 문항 은행 표시
```erb
<!-- item_bank.html.erb -->
<% @assessment_bundles.each do |stimulus| %>
  <div class="bundle-card">
    <h3><%= stimulus.code %></h3>
    <p class="bundle-summary">
      <%= truncate(stimulus.body, length: 150) %>
    </p>

    <div class="bundle-stats">
      <span class="stat">
        <strong>객관식:</strong> <%= stimulus.bundle_metadata['mcq_count'] %>개
      </span>
      <span class="stat">
        <strong>서술형:</strong> <%= stimulus.bundle_metadata['constructed_count'] %>개
      </span>
      <span class="stat">
        <strong>예상 시간:</strong> <%= stimulus.bundle_metadata['estimated_time_minutes'] %>분
      </span>
    </div>

    <div class="bundle-concepts">
      <strong>핵심 요소:</strong>
      <% stimulus.bundle_metadata['key_concepts']&.each do |concept| %>
        <span class="concept-badge"><%= concept %></span>
      <% end %>
    </div>

    <div class="bundle-actions">
      <%= link_to "상세보기", researcher_stimulus_path(stimulus) %>
      <%= link_to "문항 편집", edit_researcher_stimulus_path(stimulus) %>
    </div>
  </div>
<% end %>
```

## 🔍 검증 로직

### Bundle Integrity Validator
```ruby
class BundleIntegrityValidator
  def initialize(stimulus)
    @stimulus = stimulus
    @errors = []
  end

  def validate!
    check_code_presence
    check_items_exist
    check_item_codes_match
    check_metadata_accuracy

    { valid: @errors.empty?, errors: @errors }
  end

  private

  def check_code_presence
    @errors << "지문 코드가 없습니다" if @stimulus.code.blank?
  end

  def check_items_exist
    if @stimulus.items.empty?
      @errors << "연결된 문항이 없습니다"
    end
  end

  def check_item_codes_match
    actual_codes = @stimulus.items.pluck(:code).sort
    stored_codes = @stimulus.item_codes.sort

    if actual_codes != stored_codes
      @errors << "문항 코드 불일치: stored=#{stored_codes}, actual=#{actual_codes}"
    end
  end

  def check_metadata_accuracy
    meta = @stimulus.bundle_metadata
    actual_mcq = @stimulus.items.where(item_type: 'mcq').count
    actual_constructed = @stimulus.items.where(item_type: 'constructed').count

    if meta['mcq_count'] != actual_mcq
      @errors << "객관식 개수 불일치: meta=#{meta['mcq_count']}, actual=#{actual_mcq}"
    end

    if meta['constructed_count'] != actual_constructed
      @errors << "서술형 개수 불일치: meta=#{meta['constructed_count']}, actual=#{actual_constructed}"
    end
  end
end
```

## 📝 다음 단계

1. ✅ 스키마 분석 완료
2. 🔄 마이그레이션 파일 생성 (진행중)
3. ⏳ 모델 업데이트
4. ⏳ PdfItemParserService 리팩토링
5. ⏳ item_bank 뷰 재설계
6. ⏳ CLAUDE.md 문서화
7. ⏳ 검증 로직 추가
8. ⏳ 전체 테스트

## 🐛 알려진 이슈

- 없음 (신규 설계)

## 📌 참고사항

- 기존 데이터 마이그레이션 필요 시 별도 스크립트 작성 필요
- 지문 코드 생성 규칙: `STIM_#{Time.now.to_i}_#{SecureRandom.hex(4)}`
- 문항 코드는 PDF에서 추출하거나 GPT-4가 생성
