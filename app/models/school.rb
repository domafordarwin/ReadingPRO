class School < ApplicationRecord
  has_many :students, dependent: :destroy
  has_many :school_assessments, dependent: :destroy

  validates :name, presence: true
end
