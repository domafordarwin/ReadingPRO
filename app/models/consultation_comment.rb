# frozen_string_literal: true

class ConsultationComment < ApplicationRecord
  # Associations
  belongs_to :consultation_post
  belongs_to :created_by, class_name: "User"

  # Validations
  validates :content, presence: true

  # Callbacks
  before_validation :set_teacher_reply_flag
  after_create :update_post_activity
  after_create :mark_post_as_answered, if: :is_teacher_reply?

  # Scopes
  scope :recent, -> { order(created_at: :asc) }
  scope :by_teacher, -> { where(is_teacher_reply: true) }
  scope :by_student, -> { where(is_teacher_reply: false) }

  # Instance methods
  def from_teacher?
    created_by&.role == 'diagnostic_teacher'
  end

  def from_student?
    created_by&.student?
  end

  private

  def set_teacher_reply_flag
    self.is_teacher_reply = (created_by&.role == 'diagnostic_teacher')
  end

  def update_post_activity
    consultation_post.touch(:last_activity_at)
  end

  def mark_post_as_answered
    consultation_post.mark_as_answered! if consultation_post.open?
  end
end
