# frozen_string_literal: true

class ConsultationComment < ApplicationRecord
  belongs_to :consultation_post
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
