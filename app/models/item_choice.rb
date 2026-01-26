class ItemChoice < ApplicationRecord
  belongs_to :item
  has_one :choice_score
  has_many :responses, foreign_key: :selected_choice_id

  validates :choice_no, presence: true, numericality: { only_integer: true }
  validates :choice_no, uniqueness: { scope: :item_id }
  validates :content, presence: true
end
