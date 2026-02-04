# frozen_string_literal: true

class ItemChoice < ApplicationRecord
  belongs_to :item
  has_many :responses, foreign_key: "selected_choice_id", dependent: :destroy

  validates :choice_no, presence: true, uniqueness: { scope: :item_id }
  validates :content, presence: true
end
