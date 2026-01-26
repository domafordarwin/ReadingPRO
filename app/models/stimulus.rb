class Stimulus < ApplicationRecord
  has_many :items

  validates :code, uniqueness: true, allow_nil: true
end
