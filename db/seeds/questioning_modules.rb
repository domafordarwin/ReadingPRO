# frozen_string_literal: true

# =============================================================================
# Questioning Modules Seed Data
# 수준별 발문 학습 모듈 테스트 데이터 (4수준 x 1모듈)
#
# MD 파일 기반 책 내용:
#   L1(초저): 코끼리와 함께 사는 세상
#   L2(초고): 공감 슈퍼맨
#   L3(중등): 나는 선량한 기후파괴자입니다
#   L4(고등): 냉정한 이타주의자
# =============================================================================

puts "Creating Questioning Modules..."

# ---------------------------------------------------------------------------
# Find teacher (creator)
# ---------------------------------------------------------------------------
teacher = Teacher.first
unless teacher
  puts "  [SKIP] No teacher found. Skipping questioning modules."
  return
end

# ---------------------------------------------------------------------------
# Step 1: Create ReadingStimulus for each level's book
# ---------------------------------------------------------------------------
BOOKS = [
  {
    level: "elementary_low",
    title: "코끼리와 함께 사는 세상",
    body: <<~TEXT,
      아프리카 초원에 코끼리 가족이 살고 있었어요. 엄마 코끼리, 아빠 코끼리, 그리고 아기 코끼리 '꼬미'가 함께 다녔어요.

      어느 날, 꼬미는 숲에서 길을 잃었어요. 무서웠지만 용기를 내어 엄마를 찾아 걸었어요. 길을 가다 다친 새를 발견한 꼬미는 코로 조심스럽게 새를 들어 올려 안전한 곳에 내려놓았어요.

      드디어 엄마 코끼리를 만난 꼬미! 엄마는 코를 꼬미에게 감으며 말했어요. "넌 참 용감하고 따뜻한 아이야." 코끼리들은 가족이 다치거나 세상을 떠나면 오랫동안 슬퍼하며 함께 애도해요. 그것은 코끼리들이 서로를 얼마나 사랑하는지 보여주는 거예요.

      하지만 사람들이 코끼리의 상아를 노리고, 숲을 없애면서 코끼리들은 갈 곳을 잃어가고 있어요. 코끼리가 사라지면 숲도 변하고, 다른 동물들도 힘들어져요. 우리는 코끼리와 함께 살아가는 방법을 찾아야 해요.
    TEXT
    grade_level: "elementary_low",
    word_count: 280
  },
  {
    level: "elementary_high",
    title: "공감 슈퍼맨",
    body: <<~TEXT,
      "만약 너에게 초능력이 생긴다면 뭘 하고 싶어?"

      선생님의 질문에 아이들은 저마다 외쳤어요. "하늘을 날고 싶어요!" "투명인간이요!" 그런데 민준이만 조용히 생각하다 말했어요. "저는... 다른 사람의 마음을 읽는 능력이요."

      어느 날, 민준이는 정말 신기한 일을 겪었어요. 혼자 울고 있는 친구 수아의 마음이 느껴진 거예요. 수아는 부모님이 매일 싸워서 속상했어요. 민준이는 아무 말 없이 수아 옆에 앉아 있었어요. "고마워, 민준아. 네가 옆에 있어줘서 좀 나아졌어."

      선생님은 이렇게 말씀하셨어요. "공감이란, 상대방의 마음속에 들어가 그 사람의 눈으로 세상을 보는 거야. 그러려면 세 단계가 필요해. 첫째, 잘 읽기. 둘째, 깊이 생각하기. 셋째, 행동하기."

      하지만 공감에도 경계가 필요해요. 친구의 잘못을 무조건 공감해 주는 것이 항상 좋은 일은 아니에요. 때로는 솔직하게 말해주는 것도 진정한 공감이에요.

      "세상을 변화시키는 공감 초능력!" 민준이는 결심했어요. 매일 한 명의 친구에게 먼저 "괜찮아?" 하고 물어보기로요.
    TEXT
    grade_level: "elementary_high",
    word_count: 380
  },
  {
    level: "middle",
    title: "나는 선량한 기후파괴자입니다",
    body: <<~TEXT,
      우리는 모두 기후파괴자다. 아침에 스마트폰 알람으로 일어나고, 따뜻한 물로 샤워하고, 자동차로 출퇴근하고, 에어컨이 나오는 건물에서 일한다. 이 모든 행위가 이산화탄소를 배출한다.

      그런데 왜 우리는 행동을 바꾸지 못할까?

      첫째, '학습된 무력감'이 있다. "나 혼자 바꿔봤자 뭐가 달라지겠어?"라는 생각이 행동을 가로막는다. 심리학에서는 이를 개인이 반복된 실패 경험으로 인해 더 이상 시도하지 않게 되는 현상이라고 설명한다.

      둘째, '확증 편향'이 작동한다. 사람들은 자신의 기존 믿음을 확인해주는 정보만 받아들이고, 불편한 사실은 무시한다. "기후변화는 자연적인 현상이야"라는 주장에 끌리는 것도 이 때문이다.

      셋째, 다양한 '변명 논리'가 있다. "좋은 의도에서 한 거야", "신기술이 해결해 줄 거야", "다른 나라가 더 많이 배출하잖아." 이런 변명들은 진짜 문제와 마주하는 것을 피하게 만든다.

      그러나 '선량한 기후파괴자'라는 자기인식이야말로 변화의 출발점이다. 나의 행동이 기후에 미치는 영향을 정직하게 인정할 때, 비로소 개인의 실천과 사회 제도의 변화를 동시에 추구할 수 있다.
    TEXT
    grade_level: "middle_low",
    word_count: 420
  },
  {
    level: "high",
    title: "냉정한 이타주의자",
    body: <<~TEXT,
      윌리엄 맥어스킬은 묻는다. "당신의 선의는 정말로 세상을 더 낫게 만들고 있는가?"

      우리는 흔히 이타적 행동을 '따뜻한 가슴'으로 시작한다. 뉴스에서 본 비극에 마음이 아파 기부하고, 가까운 이웃의 어려움에 자원봉사를 나간다. 하지만 맥어스킬은 이것만으로는 충분하지 않다고 주장한다. '따뜻한 가슴'에 '차가운 머리'를 더해야 한다는 것이다.

      사적인 비극을 계기로 특정 질병 연구에 거액을 기부하는 사례를 보자. 감정적으로는 이해할 수 있지만, 같은 금액으로 말라리아 예방에 사용했다면 수백 배 더 많은 생명을 구할 수 있었을지 모른다. 이것이 '효과적 이타주의(Effective Altruism)'의 핵심이다.

      그러나 이 논리에도 한계가 있다. 인간의 선의를 '효율'로만 환산하면, 가까운 이웃의 고통은 통계 속에서 사라진다. '더 많은 생명을 구하는 선택'과 '내가 책임감을 느끼는 가까운 문제' 사이에서 우리는 어떤 기준을 세워야 하는가?

      저자는 답을 강요하지 않는다. 다만 이렇게 제안한다. "의도만으로 충분하다고 믿지 말라. 결과를 추적하고, 증거에 기반해 행동하며, 겸손하게 수정하라." 이것이 '냉정한 이타주의자'의 태도다.

      진정한 선의란, 감정과 이성 사이에서 균형을 잡는 끊임없는 노력이다.
    TEXT
    grade_level: "middle_high",
    word_count: 480
  }
].freeze

stimuli_map = {}

BOOKS.each do |book|
  stimulus = ReadingStimulus.find_or_initialize_by(title: book[:title])
  stimulus.assign_attributes(
    body: book[:body].strip,
    grade_level: book[:grade_level],
    word_count: book[:word_count],
    bundle_status: "active",
    created_by_id: teacher.id
  )
  stimulus.save!
  stimuli_map[book[:level]] = stimulus
  puts "  -> ReadingStimulus: #{stimulus.title} (id: #{stimulus.id})"
end

# ---------------------------------------------------------------------------
# Step 2: Create QuestioningModule for each level
# ---------------------------------------------------------------------------
MODULE_DEFS = [
  {
    level: "elementary_low",
    title: "코끼리와 함께 사는 세상 - 발문 학습",
    description: "코끼리 가족 이야기를 읽고, 동물의 감정과 자연 보호에 대해 발문하며 사고력을 키웁니다.",
    learning_objectives: [
      "동물의 감정을 이해하고 공감할 수 있다",
      "자연 보호의 중요성을 느끼고 실천 방법을 말할 수 있다",
      "자기 경험과 텍스트를 연결하여 발문할 수 있다"
    ],
    estimated_minutes: 20
  },
  {
    level: "elementary_high",
    title: "공감 슈퍼맨 - 발문 학습",
    description: "공감의 의미와 단계를 탐구하고, 친구 관계에서의 공감 실천을 발문으로 표현합니다.",
    learning_objectives: [
      "공감의 3단계(읽기-생각하기-행동하기)를 설명할 수 있다",
      "텍스트 근거를 들어 인물의 감정 변화를 분석할 수 있다",
      "공감의 경계와 한계에 대해 찬반 의견을 제시할 수 있다"
    ],
    estimated_minutes: 25
  },
  {
    level: "middle",
    title: "나는 선량한 기후파괴자입니다 - 발문 학습",
    description: "기후 문제를 둘러싼 심리적 장벽(무력감, 편향, 변명)을 분석하고, 개인과 사회의 책임을 탐구합니다.",
    learning_objectives: [
      "학습된 무력감, 확증 편향 등 심리 개념을 텍스트와 연결할 수 있다",
      "개인 실천과 사회 제도 변화의 관계를 논리적으로 서술할 수 있다",
      "근거를 들어 자신의 입장을 주장할 수 있다"
    ],
    estimated_minutes: 30
  },
  {
    level: "high",
    title: "냉정한 이타주의자 - 발문 학습",
    description: "효과적 이타주의의 논증 구조를 분석하고, 효율과 정의 사이의 윤리적 딜레마를 탐구합니다.",
    learning_objectives: [
      "텍스트의 전제와 세계관을 비판적으로 분석할 수 있다",
      "가설-근거-반론의 학술적 논증 구조로 발문할 수 있다",
      "효율 vs 정의 쟁점에 대해 다층적 대안을 제시할 수 있다"
    ],
    estimated_minutes: 35
  }
].freeze

MODULE_DEFS.each do |mod_def|
  stimulus = stimuli_map[mod_def[:level]]
  next unless stimulus

  qm = QuestioningModule.find_or_initialize_by(
    title: mod_def[:title]
  )
  qm.assign_attributes(
    reading_stimulus: stimulus,
    description: mod_def[:description],
    level: mod_def[:level],
    status: "active",
    learning_objectives: mod_def[:learning_objectives],
    estimated_minutes: mod_def[:estimated_minutes],
    created_by_id: teacher.id
  )
  qm.save!

  # ---------------------------------------------------------------------------
  # Step 3: Link templates for this level to the module
  # ---------------------------------------------------------------------------
  templates = QuestioningTemplate.where(level: mod_def[:level], active: true).ordered

  if templates.any? && qm.questioning_module_templates.count == 0
    templates.each_with_index do |tmpl, idx|
      QuestioningModuleTemplate.find_or_create_by!(
        questioning_module: qm,
        questioning_template: tmpl
      ) do |qmt|
        qmt.stage = tmpl.stage_before_type_cast
        qmt.position = idx
      end
    end
    puts "  -> QuestioningModule: #{qm.title} (#{templates.count} templates linked)"
  else
    puts "  -> QuestioningModule: #{qm.title} (already configured or no templates)"
  end
end

puts "Questioning Modules seeding complete!"
