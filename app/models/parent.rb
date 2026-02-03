# frozen_string_literal: true

class Parent < ApplicationRecord
  belongs_to :user
  has_many :guardian_students, dependent: :destroy
  has_many :students, through: :guardian_students

  validates :name, presence: true

  def children
    students
  end

  def primary_child
    guardian_students.primary.first&.student
  end

  def children_count
    students.count
  end
end
