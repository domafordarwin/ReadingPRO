class Attempt < ApplicationRecord
  belongs_to :form, optional: true
  has_many :responses
end
