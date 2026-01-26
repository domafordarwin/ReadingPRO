class FormItem < ApplicationRecord
  belongs_to :form
  belongs_to :item

  validates :position, presence: true, numericality: { only_integer: true }
  validates :position, uniqueness: { scope: :form_id }
  validates :item_id, uniqueness: { scope: :form_id }
  validates :points, presence: true, numericality: true
end
