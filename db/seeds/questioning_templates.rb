# frozen_string_literal: true

# =============================================================================
# Questioning Templates Seed Data
# 발문을 통한 사고력 신장 모듈 - 발문 템플릿 초기 데이터
#
# 4수준(L1~L4) x 3단계(책문열기/이야기나누기/삶적용) = 48+ 템플릿
# =============================================================================

puts "Creating Questioning Templates..."

# ---------------------------------------------------------------------------
# Helper: look up EvaluationIndicator and SubIndicator by known names
# (seeded in seeds.rb TAXONOMY block)
# ---------------------------------------------------------------------------
EI_COMP = EvaluationIndicator.find_by(code: "EI-COMP")  # 이해력
EI_AEST = EvaluationIndicator.find_by(code: "EI-AEST")  # 심미적 감수성
EI_COMM = EvaluationIndicator.find_by(code: "EI-COMM")  # 의사소통 능력

# SubIndicator lookup helper - returns nil gracefully if not found
def find_sub(indicator, name)
  return nil unless indicator
  SubIndicator.find_by(evaluation_indicator_id: indicator.id, name: name)
end

# Comprehension sub-indicators (A1, A2, A3)
SI_A1 = find_sub(EI_COMP, "사실적 이해")
SI_A2 = find_sub(EI_COMP, "추론적 이해")
SI_A3 = find_sub(EI_COMP, "비판적 이해")

# Aesthetic sub-indicators (B1, B2, B3)
SI_B1 = find_sub(EI_AEST, "문학적 표현")
SI_B2 = find_sub(EI_AEST, "정서적 공감")
SI_B3 = find_sub(EI_AEST, "문학적 가치")

# Communication sub-indicators (C1, C2, C3)
SI_C1 = find_sub(EI_COMM, "표현과 전달 능력")
SI_C2 = find_sub(EI_COMM, "사회적 상호작용")
SI_C3 = find_sub(EI_COMM, "창의적 문제해결능력")

# ---------------------------------------------------------------------------
# Batch creation helper
# ---------------------------------------------------------------------------
def create_template!(attrs)
  # Use template_text + level + stage + sort_order as unique key
  template = QuestioningTemplate.find_or_initialize_by(
    level: attrs[:level],
    stage: attrs[:stage],
    sort_order: attrs[:sort_order]
  )

  template.assign_attributes(
    evaluation_indicator_id: attrs[:evaluation_indicator_id],
    sub_indicator_id: attrs[:sub_indicator_id],
    template_type: attrs[:template_type],
    template_text: attrs[:template_text],
    scaffolding_level: attrs[:scaffolding_level],
    example_question: attrs[:example_question],
    guidance_text: attrs[:guidance_text],
    active: true
  )

  template.save!
  template
end

# =============================================================================
# L1 (초저 - 초등 1-2학년) 템플릿 12개
# =============================================================================
puts "  L1 (elementary_low) templates..."

# --- 1단계: 책문열기 (opening) --- 4개
create_template!(
  level: "elementary_low",
  stage: 1,  # opening
  sort_order: 1,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B2&.id,
  scaffolding_level: 3,
  template_text: "{주제}을(를) 해 본 적 있어요? (O/X)",
  example_question: "형제나 자매와 싸워 본 적 있어요? (O/X)",
  guidance_text: "학생의 경험과 이야기를 연결하는 질문입니다. O/X로 가볍게 시작한 뒤, '언제 그랬어요?'라고 짧게 이어 물어보세요."
)

create_template!(
  level: "elementary_low",
  stage: 1,
  sort_order: 2,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 3,
  template_text: "이 책 제목을 보면 어떤 이야기일 것 같아요? (그림 3개 중 선택)",
  example_question: "'흥부와 놀부'라는 제목을 보면 어떤 이야기일까요? (형제 이야기/동물 이야기/학교 이야기)",
  guidance_text: "제목에서 내용을 예측하는 활동입니다. 그림 카드 3장을 보여주고 고르게 하세요. 어떤 답이든 칭찬해 주세요."
)

create_template!(
  level: "elementary_low",
  stage: 1,
  sort_order: 3,
  template_type: "appreciative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C1&.id,
  scaffolding_level: 2,
  template_text: "{주제} 중에서 가장 좋아하는 것은 무엇이에요? (선택지 4개)",
  example_question: "동물 중에서 가장 좋아하는 것은? (강아지/고양이/토끼/새)",
  guidance_text: "기호와 취향을 표현하는 연습입니다. 선택 후 '왜 좋아해요?'라고 한 마디만 더 물어보세요."
)

create_template!(
  level: "elementary_low",
  stage: 1,
  sort_order: 4,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 3,
  template_text: "{사실}이(가) 맞을까요? (O/X)",
  example_question: "제비는 겨울에 따뜻한 나라로 떠나요. 맞을까요? (O/X)",
  guidance_text: "배경지식을 확인하는 O/X 문제입니다. 정답이 아니어도 괜찮아요. '같이 알아볼까요?'라고 격려해 주세요."
)

# --- 2단계: 이야기나누기 (discussion) --- 5개
create_template!(
  level: "elementary_low",
  stage: 2,
  sort_order: 1,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 3,
  template_text: "{질문}? (그림 4개 중 선택)",
  example_question: "흥부가 도와준 동물은 누구일까요? (제비/호랑이/토끼/거북이)",
  guidance_text: "이야기 내용을 그림으로 확인하는 활동입니다. 그림 카드 4장을 제시하고 알맞은 것을 고르게 하세요."
)

create_template!(
  level: "elementary_low",
  stage: 2,
  sort_order: 2,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B2&.id,
  scaffolding_level: 3,
  template_text: "{인물}은(는) 지금 어떤 기분일까요? (이모지 5개 중 선택)",
  example_question: "놀부가 박을 탔는데 도깨비가 나왔어요. 놀부는 어떤 기분일까요? (기쁨/슬픔/놀람/화남/무서움)",
  guidance_text: "등장인물의 감정을 이모지로 표현하는 활동입니다. 선택 후 '왜 그런 기분이에요?'라고 한 마디 더 물어보세요."
)

create_template!(
  level: "elementary_low",
  stage: 2,
  sort_order: 3,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 2,
  template_text: "{인물}이(가) {행동}한 것은 _____ 때문이에요.",
  example_question: "흥부가 제비를 도와준 것은 _____ 때문이에요. (마음이 착해서/엄마가 시켜서/상을 받으려고)",
  guidance_text: "빈칸 완성형 활동입니다. 선택지 3개를 제시하고, 학생이 직접 고르게 하세요. 답을 고른 뒤 '맞아요, 잘 찾았어요!' 하고 칭찬해 주세요."
)

create_template!(
  level: "elementary_low",
  stage: 2,
  sort_order: 4,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 2,
  template_text: "이야기에서 먼저 일어난 일은 무엇인가요? (그림 순서 배열)",
  example_question: "흥부 이야기를 순서대로 놓아 볼까요? (쫓겨남 → 제비 치료 → 박 심기 → 박 열기)",
  guidance_text: "사건의 순서를 배열하는 활동입니다. 그림 카드 3~4장을 섞어 두고 순서대로 놓게 하세요."
)

create_template!(
  level: "elementary_low",
  stage: 2,
  sort_order: 5,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 3,
  template_text: "이 장면에 나오는 사람은 누구인가요? (그림에서 인물 고르기)",
  example_question: "이 장면에서 누가 나왔어요? (흥부/놀부/제비/엄마)",
  guidance_text: "등장인물을 구분하는 활동입니다. 장면 그림을 보여주고, 나오는 인물의 이름을 고르게 하세요."
)

# --- 3단계: 삶적용 (application) --- 3개
create_template!(
  level: "elementary_low",
  stage: 3,
  sort_order: 1,
  template_type: "creative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B3&.id,
  scaffolding_level: 3,
  template_text: "나도 {실천 내용}할 거예요. (선택지 3개)",
  example_question: "나도 어려운 친구를 보면 _____ 할 거예요. (도와줄/응원할/같이 놀아줄)",
  guidance_text: "이야기에서 배운 점을 실천 다짐으로 연결합니다. 선택지에서 고르거나, 학생 스스로 짧게 말해도 좋아요."
)

create_template!(
  level: "elementary_low",
  stage: 3,
  sort_order: 2,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C3&.id,
  scaffolding_level: 2,
  template_text: "{인물}은(는) 그 다음에 어떻게 되었을까요? (그림 3개 중 선택)",
  example_question: "놀부는 그 다음에 어떻게 되었을까요? (착해짐/떠남/화냄)",
  guidance_text: "뒷이야기를 상상하는 활동입니다. 그림 카드를 보여주고, 학생이 고른 뒤 '왜 그렇게 생각해요?'라고 물어보세요."
)

create_template!(
  level: "elementary_low",
  stage: 3,
  sort_order: 3,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B1&.id,
  scaffolding_level: 3,
  template_text: "이 이야기에서 가장 좋았던 장면은? (그림 3개 중 선택)",
  example_question: "흥부 이야기에서 가장 재미있었던 장면은? (제비 치료/박 열기/보물 나오기)",
  guidance_text: "좋아하는 장면을 고르는 활동입니다. '왜 그 장면이 좋았어요?'라고 한 마디 더 물어보세요."
)

# =============================================================================
# L2 (초고 - 초등 5-6학년) 템플릿 12개
# =============================================================================
puts "  L2 (elementary_high) templates..."

# --- 1단계: 책문열기 (opening) --- 4개
create_template!(
  level: "elementary_high",
  stage: 1,
  sort_order: 1,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C1&.id,
  scaffolding_level: 2,
  template_text: "{주제}와(과) 관련된 경험이 있나요? 언제, 어디서, 어떤 일이 있었는지 이야기해 봅시다.",
  example_question: "형제나 가족과 갈등을 겪은 적이 있나요? 언제, 어디서, 어떤 일이 있었는지 이야기해 봅시다.",
  guidance_text: "경험을 '언제/어디서/무엇을' 구조로 서술하는 연습입니다. 학생이 한 가지만 말해도 나머지를 물어봐 주세요."
)

create_template!(
  level: "elementary_high",
  stage: 1,
  sort_order: 2,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 1,
  template_text: "'{제목}'이라는 제목에서 떠오르는 것을 모두 말해 봅시다. 어떤 이야기일지 짐작해 볼까요?",
  example_question: "'완득이'라는 제목에서 떠오르는 것을 모두 말해 봅시다. 어떤 이야기일지 짐작해 볼까요?",
  guidance_text: "제목에서 연상되는 단어나 이미지를 자유롭게 펼치는 활동입니다. 마인드맵처럼 정리할 수도 있어요."
)

create_template!(
  level: "elementary_high",
  stage: 1,
  sort_order: 3,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 1,
  template_text: "{주제}에 대해 알고 있는 것이 있나요? 친구들과 나눠 봅시다.",
  example_question: "다문화 가정에 대해 알고 있는 것이 있나요? 친구들과 나눠 봅시다.",
  guidance_text: "배경지식을 공유하는 활동입니다. 맞고 틀림보다 자유롭게 이야기하는 분위기를 만들어 주세요."
)

create_template!(
  level: "elementary_high",
  stage: 1,
  sort_order: 4,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B2&.id,
  scaffolding_level: 1,
  template_text: "이 책을 읽기 전에 어떤 내용일지 기대되나요? 가장 궁금한 점은 무엇인가요?",
  example_question: "'완득이'를 읽기 전에 가장 궁금한 점은 무엇인가요?",
  guidance_text: "기대감을 표현하게 하는 활동입니다. 궁금한 점을 적어 두면 읽은 후 확인하는 활동으로 이어갈 수 있어요."
)

# --- 2단계: 이야기나누기 (discussion) --- 5개
create_template!(
  level: "elementary_high",
  stage: 2,
  sort_order: 1,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 2,
  template_text: "[누가] [무엇을] [왜] 했을까요? 책에서 힌트를 찾아봅시다.",
  example_question: "완득이 아버지가 완득이를 떠난 까닭은 무엇일까요? 책에서 힌트를 찾아봅시다.",
  guidance_text: "'누가/무엇을/왜' 3요소 구조로 사건을 분석하는 활동입니다. 학생이 텍스트에서 근거를 찾도록 안내하세요."
)

create_template!(
  level: "elementary_high",
  stage: 2,
  sort_order: 2,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B2&.id,
  scaffolding_level: 1,
  template_text: "{인물}의 마음이 처음에는 _____, 나중에는 _____로 바뀌었어요. 왜 바뀌었을까요?",
  example_question: "완득이의 마음이 처음에는 화남, 나중에는 이해로 바뀌었어요. 왜 바뀌었을까요?",
  guidance_text: "인물의 감정 변화를 추적하는 활동입니다. 감정 단어 카드를 활용하면 표현이 풍부해집니다."
)

create_template!(
  level: "elementary_high",
  stage: 2,
  sort_order: 3,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B1&.id,
  scaffolding_level: 1,
  template_text: "가장 인상 깊은 문장이나 표현은 무엇인가요? 왜 그렇게 느꼈나요?",
  example_question: "'너도 하늘 말나리야'에서 가장 인상 깊은 표현은? 왜 그렇게 느꼈나요?",
  guidance_text: "표현을 감상하는 활동입니다. 학생이 고른 문장을 함께 읽고, 어떤 느낌인지 자유롭게 이야기하게 하세요."
)

create_template!(
  level: "elementary_high",
  stage: 2,
  sort_order: 4,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 1,
  template_text: "{사건}이(가) 일어난 원인은 무엇이고, 그 결과 어떤 일이 생겼나요?",
  example_question: "완득이가 동주에게 화를 낸 원인은 무엇이고, 그 결과 어떤 일이 생겼나요?",
  guidance_text: "원인과 결과를 연결하여 추론하는 활동입니다. '때문에'와 '그래서'라는 말을 사용하도록 안내하세요."
)

create_template!(
  level: "elementary_high",
  stage: 2,
  sort_order: 5,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 0,
  template_text: "{인물1}과(와) {인물2}은(는) 어떤 점이 비슷하고, 어떤 점이 다른가요?",
  example_question: "완득이와 동주 선생님은 어떤 점이 비슷하고, 어떤 점이 다른가요?",
  guidance_text: "두 인물을 비교하는 활동입니다. 표를 그려 '비슷한 점 / 다른 점'으로 나누어 정리하면 좋습니다."
)

# --- 3단계: 삶적용 (application) --- 3개
create_template!(
  level: "elementary_high",
  stage: 3,
  sort_order: 1,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 1,
  template_text: "{쟁점}에 대해 찬성하나요, 반대하나요? 이유를 2가지 말해 봅시다.",
  example_question: "완득이 아버지가 완득이를 떠난 것은 어쩔 수 없는 선택이었을까요? 찬성/반대와 이유 2가지를 말해 봅시다.",
  guidance_text: "찬반 의견을 근거와 함께 말하는 활동입니다. '나는 ~라고 생각해요. 왜냐하면 첫째 ~, 둘째 ~' 구조를 안내하세요."
)

create_template!(
  level: "elementary_high",
  stage: 3,
  sort_order: 2,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C3&.id,
  scaffolding_level: 0,
  template_text: "{문제}을(를) 해결할 수 있는 방법 2가지를 생각해 봅시다. 어떤 방법이 더 좋을까요?",
  example_question: "완득이처럼 어려운 가정 환경에 있는 친구를 도울 수 있는 방법 2가지는? 어떤 것이 더 좋을까요?",
  guidance_text: "두 가지 해결 방법을 비교하는 활동입니다. 각 방법의 장점과 단점을 함께 생각하게 하세요."
)

create_template!(
  level: "elementary_high",
  stage: 3,
  sort_order: 3,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B3&.id,
  scaffolding_level: 0,
  template_text: "이 이야기의 주제는 우리 생활에서 어떤 것과 연결되나요? 구체적으로 말해 봅시다.",
  example_question: "'완득이'에서 다룬 편견과 차별의 주제는 우리 학교에서 어떤 경우에 나타나나요?",
  guidance_text: "작품의 주제를 자신의 삶과 연결하는 활동입니다. 학교, 가정, 뉴스 등 구체적 사례를 떠올리게 하세요."
)

# =============================================================================
# L3 (중등 - 중학생) 템플릿 12개
# =============================================================================
puts "  L3 (middle) templates..."

# --- 1단계: 책문열기 (opening) --- 3개
create_template!(
  level: "middle",
  stage: 1,
  sort_order: 1,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C1&.id,
  scaffolding_level: 1,
  template_text: "{주제}에 대해 (K) 알고 있는 것, (W) 알고 싶은 것, (L) 배운 것을 구분하여 정리해 봅시다.",
  example_question: "'청소년 인권'에 대해 (K) 알고 있는 것, (W) 알고 싶은 것을 정리해 봅시다. (L)은 읽은 후에 채워요.",
  guidance_text: "KWL 차트를 활용한 사전 지식 구조화 활동입니다. K열과 W열을 먼저 채우고, L열은 읽기 후 작성합니다."
)

create_template!(
  level: "middle",
  stage: 1,
  sort_order: 2,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "{주제}에 대한 나의 기존 생각은 무엇인가요? 그 생각이 어디서 비롯된 것인지 돌아봅시다.",
  example_question: "'빈부격차'에 대한 나의 기존 생각은 무엇인가요? 그 생각이 어디서(뉴스, 부모님, 경험) 비롯된 것인지 돌아봅시다.",
  guidance_text: "선입견을 인식하는 메타인지 활동입니다. '내 생각의 출처'를 찾아보게 하면 비판적 사고의 출발이 됩니다."
)

create_template!(
  level: "middle",
  stage: 1,
  sort_order: 3,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 0,
  template_text: "{주제}에 대해 알고 있는 사실을 '사실/의견/궁금한 점'으로 분류하여 정리해 봅시다.",
  example_question: "남북 분단에 대해 알고 있는 것을 '사실/의견/궁금한 점'으로 분류하여 정리해 봅시다.",
  guidance_text: "사실과 의견을 구분하는 활동입니다. 3칸 표를 제시하고, 학생들이 자유롭게 채우도록 안내하세요."
)

# --- 2단계: 이야기나누기 (discussion) --- 6개
create_template!(
  level: "middle",
  stage: 2,
  sort_order: 1,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 1,
  template_text: "만약 {조건}이(가) 달랐다면, {결과}은(는) 어떻게 되었을까요? 그렇게 생각하는 이유는?",
  example_question: "만약 흥부가 제비를 도와주지 않았다면, 이야기는 어떻게 달라졌을까요? 그렇게 생각하는 이유는?",
  guidance_text: "조건부 추론 활동입니다. '만약 ~라면, ~할 것이다. 왜냐하면 ~' 형식으로 논리적 추론을 연습합니다."
)

create_template!(
  level: "middle",
  stage: 2,
  sort_order: 2,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "이 사건을 {다른 인물}의 입장에서 본다면 어떻게 느끼고 생각했을까요?",
  example_question: "놀부의 입장에서 이 이야기를 다시 본다면, 놀부는 어떤 억울함이나 사정이 있었을까요?",
  guidance_text: "관점 전환 활동입니다. 주인공이 아닌 다른 인물의 시각에서 사건을 재해석하게 하세요."
)

create_template!(
  level: "middle",
  stage: 2,
  sort_order: 3,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B1&.id,
  scaffolding_level: 0,
  template_text: "작가가 이 장면에서 {표현 기법}을(를) 사용한 이유는? 다른 방식으로 표현했다면 어떤 효과가 있었을까요?",
  example_question: "작가가 과장법을 사용하여 놀부의 욕심을 표현한 이유는? 사실적으로 묘사했다면 느낌이 어떻게 달랐을까요?",
  guidance_text: "수사적 장치를 분석하는 활동입니다. 표현 기법의 '효과'에 초점을 맞추어 이야기를 나누세요."
)

create_template!(
  level: "middle",
  stage: 2,
  sort_order: 4,
  template_type: "factual",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A1&.id,
  scaffolding_level: 1,
  template_text: "이 글의 전체 구조는 어떻게 되어 있나요? (발단-전개-위기-절정-결말 / 서론-본론-결론 등)",
  example_question: "'흥부와 놀부'의 구조를 발단-전개-위기-절정-결말로 나누어 정리해 봅시다.",
  guidance_text: "텍스트 구조를 분석하는 활동입니다. 글의 종류에 맞는 구조 틀을 제시하고 핵심 내용을 채우게 하세요."
)

create_template!(
  level: "middle",
  stage: 2,
  sort_order: 5,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 0,
  template_text: "이 작품이 전달하려는 핵심 주제(메시지)는 무엇이라고 생각하나요? 텍스트에서 근거를 찾아 봅시다.",
  example_question: "'흥부와 놀부'가 전달하려는 핵심 메시지는 무엇인가요? 어떤 장면에서 그것을 알 수 있나요?",
  guidance_text: "주제를 추론하는 활동입니다. '나는 ~라고 생각합니다. 왜냐하면 텍스트에서 ~라고 했기 때문입니다.' 형식을 안내하세요."
)

create_template!(
  level: "middle",
  stage: 2,
  sort_order: 6,
  template_type: "inferential",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B2&.id,
  scaffolding_level: 0,
  template_text: "{인물}이(가) {행동}을(를) 할 때, 어떤 심리적 갈등이 있었을까요? 그 갈등의 원인은?",
  example_question: "완득이가 엄마를 처음 만났을 때, 어떤 심리적 갈등이 있었을까요? 그 갈등의 원인은?",
  guidance_text: "인물의 심리를 깊이 분석하는 활동입니다. 겉으로 드러난 행동과 속마음의 차이에 주목하게 하세요."
)

# --- 3단계: 삶적용 (application) --- 3개
create_template!(
  level: "middle",
  stage: 3,
  sort_order: 1,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "이 작품의 {갈등}은(는) 우리 사회의 어떤 문제와 닮아 있나요? 구체적 사례를 들어 설명해 봅시다.",
  example_question: "'흥부와 놀부'의 빈부격차 갈등은 현대 사회의 어떤 현상과 비슷한가요? 뉴스나 경험에서 사례를 찾아 봅시다.",
  guidance_text: "문학과 사회를 연결하는 활동입니다. 학생들이 뉴스, 경험, 다른 책에서 비슷한 사례를 찾도록 안내하세요."
)

create_template!(
  level: "middle",
  stage: 3,
  sort_order: 2,
  template_type: "critical",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B3&.id,
  scaffolding_level: 0,
  template_text: "{가치 A}와(과) {가치 B} 중 어떤 것이 더 중요하다고 생각하나요? 어떤 기준으로 판단하나요?",
  example_question: "정의(처벌)와 용서 중 어떤 것이 놀부에게 더 필요했을까요? 어떤 기준으로 판단했나요?",
  guidance_text: "가치 갈등 토론 활동입니다. 정답이 없는 질문임을 강조하고, 다양한 의견을 존중하는 분위기를 만드세요."
)

create_template!(
  level: "middle",
  stage: 3,
  sort_order: 3,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C3&.id,
  scaffolding_level: 0,
  template_text: "이 작품에서 다루는 문제를 해결하기 위해 우리가 할 수 있는 구체적인 방법을 제안해 봅시다.",
  example_question: "빈부격차 문제를 줄이기 위해 학교, 지역사회, 정부 차원에서 각각 어떤 노력을 할 수 있을까요?",
  guidance_text: "실천 방안을 제안하는 활동입니다. 개인/학교/사회 수준으로 나누어 구체적인 행동을 떠올리게 하세요."
)

# =============================================================================
# L4 (고등 - 고등학생) 템플릿 12개
# =============================================================================
puts "  L4 (high) templates..."

# --- 1단계: 책문열기 (opening) --- 3개
create_template!(
  level: "high",
  stage: 1,
  sort_order: 1,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "{주제}에 대한 나의 선입견은 무엇인가요? 그 선입견이 형성된 배경(매체, 교육, 경험)은? 읽기에 어떤 영향을 미칠 수 있나요?",
  example_question: "'빈부격차'에 대한 나의 기존 생각은? 그 생각이 어떤 매체나 경험에서 형성되었나요? 이것이 텍스트 해석에 어떤 영향을 줄 수 있나요?",
  guidance_text: "메타인지적 자기 분석 활동입니다. 자신의 사고 과정과 그 배경을 성찰하게 하여 비판적 읽기의 토대를 마련합니다."
)

create_template!(
  level: "high",
  stage: 1,
  sort_order: 2,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "{주제}에 대해 사회에서 일반적으로 받아들여지는 관점은 무엇인가요? 그 관점에서 간과되고 있는 시각은?",
  example_question: "전래동화에 대해 우리가 당연하게 여기는 관점은? '권선징악'이라는 해석에서 간과되는 시각은 무엇인가요?",
  guidance_text: "편향 인식 활동입니다. 사회적으로 통용되는 관점의 한계를 인식하고, 대안적 시각을 탐색하게 합니다."
)

create_template!(
  level: "high",
  stage: 1,
  sort_order: 3,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C1&.id,
  scaffolding_level: 0,
  template_text: "이 텍스트의 주제는 어떤 학문 분야(경제학, 심리학, 사회학, 역사학 등)와 관련되나요? 학제적 배경 지식을 정리해 봅시다.",
  example_question: "'흥부와 놀부'의 주제는 경제학(분배), 심리학(질투), 윤리학(정의) 중 어디와 가장 관련이 깊나요? 각 분야의 핵심 개념을 정리해 봅시다.",
  guidance_text: "학제적 연결 활동입니다. 문학 텍스트를 다양한 학문의 렌즈로 바라보는 시각을 길러줍니다."
)

# --- 2단계: 이야기나누기 (discussion) --- 6개
create_template!(
  level: "high",
  stage: 2,
  sort_order: 1,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "이 텍스트가 전제하는 세계관(가치 체계)은 무엇인가요? 어떤 목소리가 텍스트에서 배제되어 있나요?",
  example_question: "'착한 흥부=복, 나쁜 놀부=벌'이라는 구조가 전제하는 가치 체계는? 놀부 아내, 흥부 자녀 등 배제된 목소리는?",
  guidance_text: "이데올로기 비판 활동입니다. 텍스트의 숨은 전제와 권력 구조를 분석하게 합니다. 정답이 아닌 '다양한 해석'에 초점을 두세요."
)

create_template!(
  level: "high",
  stage: 2,
  sort_order: 2,
  template_type: "inferential",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A2&.id,
  scaffolding_level: 0,
  template_text: "'{가설}'이라는 가설을 세우고, 텍스트에서 이를 뒷받침하거나 반박하는 근거를 찾아 논증해 봅시다.",
  example_question: "'놀부의 탐욕은 사회 구조적 불안의 표현이다'라는 가설을 세우고, 텍스트에서 근거를 찾아 논증해 봅시다.",
  guidance_text: "가설 검증 활동입니다. 학생 스스로 가설을 세우고, 텍스트 내 근거를 찾아 논증하는 학술적 사고를 연습합니다."
)

create_template!(
  level: "high",
  stage: 2,
  sort_order: 3,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C3&.id,
  scaffolding_level: 0,
  template_text: "이 텍스트의 주제를 {타 학문 분야}의 관점에서 재해석한다면 어떤 새로운 의미가 드러나나요?",
  example_question: "'흥부와 놀부'를 경제학(부의 분배), 심리학(형제 관계 역학), 사회학(계층 이동) 관점에서 각각 재해석해 봅시다.",
  guidance_text: "학제 간 연결 활동입니다. 하나의 텍스트를 여러 학문의 렌즈로 분석하여 다층적 이해를 이끌어 냅니다."
)

create_template!(
  level: "high",
  stage: 2,
  sort_order: 4,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B1&.id,
  scaffolding_level: 0,
  template_text: "작가가 사용한 서사 전략(시점, 구성, 문체, 상징 등)은 주제 전달에 어떤 효과를 내고 있나요?",
  example_question: "'흥부와 놀부'에서 권선징악적 결말 구성이 주제 전달에 미치는 효과는? 열린 결말이었다면 어떻게 달라졌을까요?",
  guidance_text: "서사 전략을 분석하는 활동입니다. 형식(어떻게 쓰여졌는가)이 내용(무엇을 전달하는가)에 미치는 영향에 주목하세요."
)

create_template!(
  level: "high",
  stage: 2,
  sort_order: 5,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "이 사건을 서로 다른 입장(등장인물, 시대, 문화)에서 분석하면 어떤 해석의 차이가 생기나요?",
  example_question: "흥부전을 조선 시대 양반과 서민, 그리고 현대인의 시각에서 각각 해석하면 어떤 차이가 있나요?",
  guidance_text: "다시점 분석 활동입니다. 동일한 사건이 관점에 따라 전혀 다르게 해석될 수 있음을 경험하게 합니다."
)

create_template!(
  level: "high",
  stage: 2,
  sort_order: 6,
  template_type: "appreciative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B3&.id,
  scaffolding_level: 0,
  template_text: "이 작품과 유사한 주제를 다룬 다른 작품(문학, 영화, 예술)은 무엇인가요? 두 작품의 관점은 어떻게 다른가요?",
  example_question: "'흥부와 놀부'와 셰익스피어의 '리어 왕'은 모두 가족 갈등을 다룹니다. 두 작품의 관점은 어떻게 다른가요?",
  guidance_text: "상호텍스트성 분석 활동입니다. 서로 다른 문화권의 작품을 비교하며 보편적 주제와 문화적 차이를 탐구합니다."
)

# --- 3단계: 삶적용 (application) --- 3개
create_template!(
  level: "high",
  stage: 3,
  sort_order: 1,
  template_type: "creative",
  evaluation_indicator_id: EI_AEST&.id,
  sub_indicator_id: SI_B1&.id,
  scaffolding_level: 0,
  template_text: "이 작품의 {요소}를 바꾸거나 뒤집는다면 어떤 새로운 의미가 만들어지나요? 핵심 메시지에는 어떤 영향을 미치나요?",
  example_question: "놀부가 벌을 받지 않는 결말로 바꾼다면, 이 이야기는 어떤 새로운 의미를 가지게 되나요?",
  guidance_text: "창의적 재구성 활동입니다. 원작의 요소를 변형하여 주제의 다층성을 탐구합니다. '만약 ~라면' 사고 실험을 권합니다."
)

create_template!(
  level: "high",
  stage: 3,
  sort_order: 2,
  template_type: "creative",
  evaluation_indicator_id: EI_COMM&.id,
  sub_indicator_id: SI_C3&.id,
  scaffolding_level: 0,
  template_text: "이 작품이 제기하는 문제를 해결하기 위한 정책이나 제도를 제안한다면? 그 정책의 기대 효과와 윤리적 함의는?",
  example_question: "빈부격차를 해결하기 위한 정책(기본소득, 누진세 등)을 제안하고, 그 정책의 기대 효과와 윤리적 한계를 분석해 봅시다.",
  guidance_text: "정책 제안 활동입니다. 문학의 문제 의식을 현실 정책으로 연결하며, 기대 효과뿐 아니라 부작용과 윤리적 쟁점도 함께 고려하게 하세요."
)

create_template!(
  level: "high",
  stage: 3,
  sort_order: 3,
  template_type: "critical",
  evaluation_indicator_id: EI_COMP&.id,
  sub_indicator_id: SI_A3&.id,
  scaffolding_level: 0,
  template_text: "이번 발문 활동에서 나는 어떤 사고 과정을 거쳤나요? 내가 만든 발문의 강점, 한계, 개선 방향을 분석해 봅시다.",
  example_question: "오늘 내가 만든 발문은 어떤 사고(사실 확인, 추론, 비판, 창의)를 유도했나요? 강점과 개선점은 무엇인가요?",
  guidance_text: "메타인지 성찰 활동입니다. 자신의 발문 과정을 객관적으로 돌아보고, 사고 전략을 명시화하게 합니다."
)

# =============================================================================
# Summary
# =============================================================================
total = QuestioningTemplate.count
puts ""
puts "=== Questioning Templates Seeded ==="
puts "  Total templates: #{total}"
%w[elementary_low elementary_high middle high].each do |lv|
  cnt = QuestioningTemplate.where(level: lv).count
  label = { "elementary_low" => "L1 (초저)", "elementary_high" => "L2 (초고)", "middle" => "L3 (중등)", "high" => "L4 (고등)" }[lv]
  puts "  #{label}: #{cnt} templates"
end
puts "======================================"
