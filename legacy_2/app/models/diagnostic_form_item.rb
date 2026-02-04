# frozen_string_literal: true

class DiagnosticFormItem < ApplicationRecord
  belongs_to :diagnostic_form
  belongs_to :item

  validates :position, presence: true, uniqueness: { scope: :diagnostic_form_id }
  validates :item_id, uniqueness: { scope: :diagnostic_form_id }
end
