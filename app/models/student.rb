class Student < ApplicationRecord
  belongs_to :school
  belongs_to :user, optional: true

  has_many :attempts, dependent: :destroy
  has_many :guardian_students, dependent: :destroy
  has_many :guardians, through: :guardian_students, source: :guardian_user
  has_many :consultation_posts, dependent: :destroy
  has_many :consultation_requests, dependent: :destroy

  validates :name, presence: true
  validates :school, presence: true

  scope :by_grade, ->(grade) { where(grade: grade) }
  scope :by_class, ->(class_number) { where(class_number: class_number) }

  def full_identifier
    "#{grade}학년 #{class_number}반 #{student_number}번 #{name}"
  end

  def recent_consultations(limit = 5)
    consultation_posts.recent.limit(limit)
  end

  def open_consultations_count
    consultation_posts.open_posts.count
  end
end
