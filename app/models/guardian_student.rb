# frozen_string_literal: true

class GuardianStudent < ApplicationRecord
  belongs_to :parent
  belongs_to :student

  RELATIONSHIPS = %w[mother father guardian other].freeze

  validates :parent_id, uniqueness: { scope: :student_id,
                                       message: "Parent already linked to this student" }
  validates :relationship, inclusion: { in: RELATIONSHIPS }, allow_nil: true
  validates :can_view_results, inclusion: { in: [ true, false ] }
  validates :can_request_consultations, inclusion: { in: [ true, false ] }

  scope :primary, -> { where(primary_contact: true) }
  scope :can_view_results, -> { where(can_view_results: true) }
  scope :can_request_consultation, -> { where(can_request_consultations: true) }
end
