class Rubric < ApplicationRecord
  belongs_to :item
  has_many :rubric_criteria, -> { order(:position) }

  validates :item_id, uniqueness: true
end
