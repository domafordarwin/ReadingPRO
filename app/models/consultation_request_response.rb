# frozen_string_literal: true

class ConsultationRequestResponse < ApplicationRecord
  belongs_to :consultation_request
  belongs_to :created_by, class_name: "User"

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
