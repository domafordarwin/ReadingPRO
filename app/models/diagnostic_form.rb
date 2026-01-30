# frozen_string_literal: true

class DiagnosticForm < ApplicationRecord
class DiagnosticForm < ApplicationRecord
  belongs_to :teacher, foreign_key: 'created_by_id', optional: true
  has_many :diagnostic_form_items, dependent: :destroy
  has_many :items, through: :diagnostic_form_items
  has_many :student_attempts, dependent: :destroy

  enum :status, { draft: 'draft', active: 'active', archived: 'archived' }

  validates :name, presence: true
end

end
