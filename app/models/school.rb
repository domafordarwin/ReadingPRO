# frozen_string_literal: true

class School < ApplicationRecord
  has_many :students, dependent: :destroy
  has_many :teachers, dependent: :destroy
  has_one :school_portfolio, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end

end
