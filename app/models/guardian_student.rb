# frozen_string_literal: true

class GuardianStudent < ApplicationRecord
  belongs_to :guardian_user, class_name: "User"
  belongs_to :student

  validates :guardian_user_id, uniqueness: { scope: :student_id }
end
