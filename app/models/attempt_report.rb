# frozen_string_literal: true

class AttemptReport < ApplicationRecord
  belongs_to :student_attempt

  enum :performance_level, { advanced: 'advanced', proficient: 'proficient', developing: 'developing', beginning: 'beginning' }

  validates :student_attempt_id, uniqueness: true

  # 보고서 상태: generated_at 여부로 판단
  def status
    generated_at.present? ? 'published' : 'draft'
  end

  def published?
    status == 'published'
  end
end
