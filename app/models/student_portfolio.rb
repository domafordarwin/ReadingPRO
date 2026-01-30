# frozen_string_literal: true

class StudentPortfolio < ApplicationRecord
class StudentPortfolio < ApplicationRecord
  belongs_to :student

  validates :student_id, uniqueness: true
end

end
