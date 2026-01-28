class Student < ApplicationRecord
  belongs_to :school

  has_many :attempts, dependent: :destroy
  has_many :guardian_students, dependent: :destroy
  has_many :guardians, through: :guardian_students, source: :guardian_user

  validates :name, presence: true
  validates :school, presence: true

  scope :by_grade, ->(grade) { where(grade: grade) }
  scope :by_class, ->(class_number) { where(class_number: class_number) }

  def full_identifier
    "#{grade}학년 #{class_number}반 #{student_number}번 #{name}"
  end
end
