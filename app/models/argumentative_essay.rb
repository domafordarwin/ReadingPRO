# frozen_string_literal: true

class ArgumentativeEssay < ApplicationRecord
  belongs_to :questioning_session
  belongs_to :feedback_publisher, class_name: "User", foreign_key: "feedback_published_by_id", optional: true

  # Validations
  validates :topic, presence: true
  validates :essay_text, presence: true
  validates :ai_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :teacher_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  def feedback_published?
    feedback_published_at.present?
  end

  def ai_feedback_text
    ai_feedback&.dig("overall_feedback")
  end

  def ai_strengths
    ai_feedback&.dig("strengths") || []
  end

  def ai_weaknesses
    ai_feedback&.dig("weaknesses") || []
  end

  def ai_improvements
    ai_feedback&.dig("improvements") || []
  end

  def ai_section_scores
    {
      claim_clarity: ai_feedback&.dig("claim_clarity"),
      evidence_quality: ai_feedback&.dig("evidence_quality"),
      counterargument: ai_feedback&.dig("counterargument"),
      logical_structure: ai_feedback&.dig("logical_structure"),
      language_quality: ai_feedback&.dig("language_quality")
    }
  end

  def final_score
    teacher_score || ai_score
  end
end
