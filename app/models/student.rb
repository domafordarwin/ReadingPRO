# frozen_string_literal: true

class Student < ApplicationRecord
class Student < ApplicationRecord
  belongs_to :user
  belongs_to :school
  has_many :student_attempts, dependent: :destroy
  has_one :student_portfolio, dependent: :destroy

  validates :name, presence: true
end

end
