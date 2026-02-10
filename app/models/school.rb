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
    # 새 형식 (prefix_S-0001) + 구 형식 (RPS_0001) 모두 검색
    all_names = students.pluck(:name)
    new_max = all_names.filter_map { |n| n.match(/_S-(\d+)\z/)&.captures&.first&.to_i }.max || 0
    old_max = all_names.filter_map { |n| n.match(/\ARPS_(\d+)\z/)&.captures&.first&.to_i }.max || 0
    [new_max, old_max].max + 1
  end
end
