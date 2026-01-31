# frozen_string_literal: true

class SchoolPortfolio < ApplicationRecord
  belongs_to :school

  validates :school_id, uniqueness: true

end
