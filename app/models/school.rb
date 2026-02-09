# frozen_string_literal: true

class School < ApplicationRecord
  has_many :students, dependent: :destroy
  has_many :teachers, dependent: :destroy
  has_many :school_admin_profiles, dependent: :destroy
  has_many :diagnostic_assignments, dependent: :destroy
  has_many :questioning_module_assignments, dependent: :destroy
  has_one :school_portfolio, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def next_student_sequence
    max_seq = students.where("name LIKE 'RPS_%'")
                      .pluck(:name)
                      .filter_map { |n| n.match(/RPS_(\d+)/)&.captures&.first&.to_i }
                      .max || 0
    max_seq + 1
  end
end
