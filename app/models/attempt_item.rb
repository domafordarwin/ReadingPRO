# frozen_string_literal: true

class AttemptItem < ApplicationRecord
  belongs_to :attempt
  belongs_to :item

  has_one :response, dependent: :nullify

  validates :position, presence: true, uniqueness: { scope: :attempt_id }
  validates :item_id, uniqueness: { scope: :attempt_id }
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }

  default_scope { order(:position) }

  # Copy form_items to attempt_items when starting an attempt
  def self.snapshot_from_form(attempt)
    attempt.form.form_items.find_each do |form_item|
      create!(
        attempt: attempt,
        item_id: form_item.item_id,
        position: form_item.position,
        points: form_item.points,
        required: form_item.required
      )
    end
  end
end
