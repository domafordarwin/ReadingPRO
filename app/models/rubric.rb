class Rubric < ApplicationRecord
  belongs_to :item
  has_many :rubric_criteria, -> { order(:position) }, dependent: :destroy

  validates :item_id, uniqueness: true
end
