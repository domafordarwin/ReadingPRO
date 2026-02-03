# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :user
  belongs_to :school
  has_many :student_attempts, dependent: :destroy
  has_one :student_portfolio, dependent: :destroy
  has_many :guardian_students, dependent: :destroy
  has_many :parents, through: :guardian_students
  has_many :reader_tendencies, dependent: :destroy

  validates :name, presence: true

  def primary_guardian
    guardian_students.primary.first&.parent
  end

  def parents_list
    parents
  end
end
