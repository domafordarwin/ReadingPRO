# frozen_string_literal: true

class ParentForumComment < ApplicationRecord
  # Associations
  belongs_to :parent_forum
  belongs_to :created_by, class_name: "User"

  # Validations
  validates :content, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :by_teacher, -> { where(is_teacher_reply: true) }

  # Instance methods
  def is_teacher_reply?
    is_teacher_reply == true
  end
end
