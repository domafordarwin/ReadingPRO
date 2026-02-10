# frozen_string_literal: true

class QuestioningReport < ApplicationRecord
  belongs_to :questioning_session
  belongs_to :generated_by, class_name: "User", optional: true

  # Validations
  validates :report_status, presence: true, inclusion: { in: %w[draft published] }

  # Scopes
  scope :published, -> { where(report_status: "published") }
  scope :draft, -> { where(report_status: "draft") }

  SECTION_LABELS = {
    "reading_comprehension" => "읽기 이해력",
    "critical_thinking" => "비판적 사고력",
    "creative_thinking" => "창의적 사고력",
    "inferential_reasoning" => "추론 능력",
    "vocabulary_usage" => "어휘 활용",
    "text_connection" => "텍스트 연결 능력",
    "personal_application" => "삶 적용 능력",
    "metacognition" => "메타인지 능력",
    "communication" => "의사소통 능력",
    "discussion_competency" => "토론 역량",
    "argumentative_writing" => "논증적 글쓰기"
  }.freeze

  LITERACY_LEVELS = {
    "beginning" => "기초",
    "developing" => "발전",
    "proficient" => "숙달",
    "advanced" => "심화"
  }.freeze

  def published?
    report_status == "published"
  end

  def section_score(key)
    report_sections&.dig(key.to_s, "score")
  end

  def section_feedback(key)
    report_sections&.dig(key.to_s, "feedback")
  end

  def section_strengths(key)
    report_sections&.dig(key.to_s, "strengths") || []
  end

  def section_improvements(key)
    report_sections&.dig(key.to_s, "improvements") || []
  end

  def literacy_level_label
    LITERACY_LEVELS[literacy_level] || literacy_level
  end
end
