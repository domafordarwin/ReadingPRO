# frozen_string_literal: true

class ConsultationComment < ApplicationRecord
  belongs_to :consultation_post
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # 교사(진단담당교사, 관리자 포함)가 작성한 댓글인지 확인
  def from_teacher?
    created_by&.teacher? || created_by&.diagnostic_teacher? || created_by&.admin?
  end
end
