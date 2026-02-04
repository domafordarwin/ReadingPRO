# frozen_string_literal: true

class Rubric < ApplicationRecord
  belongs_to :item
  has_many :rubric_criteria, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :item_id }
end
