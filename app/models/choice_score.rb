class ChoiceScore < ApplicationRecord
  belongs_to :item_choice

  validates :item_choice_id, uniqueness: true
  validates :score_percent,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }
end
