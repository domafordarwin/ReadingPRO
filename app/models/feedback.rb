# frozen_string_literal: true

class Feedback < ApplicationRecord
  belongs_to :response
  belongs_to :teacher, foreign_key: "created_by_id", optional: true

  enum :feedback_type, { auto: "auto", manual: "manual" }

  validates :content, presence: true
end
