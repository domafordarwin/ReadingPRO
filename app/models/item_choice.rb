class ItemChoice < ApplicationRecord
  belongs_to :item
  has_one :choice_score
  has_many :responses, foreign_key: :selected_choice_id

  validates :choice_no, presence: true, numericality: { only_integer: true }
  validates :choice_no, uniqueness: { scope: :item_id }
  validates :content, presence: true

  def correct?
    choice_score&.is_key?
  end

  alias_method :correct, :correct?

  def choice_letter
    (choice_no.to_i + 64).chr
  end

  def choice_text
    self[:content]
  end
end
