# frozen_string_literal: true

class QuestioningModuleTemplate < ApplicationRecord
  # Associations
  belongs_to :questioning_module
  belongs_to :questioning_template

  # Validations
  validates :stage, presence: true, numericality: { only_integer: true, in: 1..3 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :questioning_template_id, uniqueness: { scope: :questioning_module_id,
    message: "is already assigned to this module" }

  # Scopes
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :ordered, -> { order(stage: :asc, position: :asc) }
  scope :required_only, -> { where(required: true) }
end
