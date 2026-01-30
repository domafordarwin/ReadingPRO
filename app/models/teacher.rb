# frozen_string_literal: true

class Teacher < ApplicationRecord
class Teacher < ApplicationRecord
  belongs_to :user
  belongs_to :school
  has_many :items, foreign_key: 'created_by_id', dependent: :destroy
  has_many :reading_stimuli, foreign_key: 'created_by_id', dependent: :destroy
  has_many :diagnostic_forms, foreign_key: 'created_by_id', dependent: :destroy
  has_many :feedbacks, foreign_key: 'created_by_id', dependent: :destroy
  has_many :response_rubric_scores, foreign_key: 'created_by_id', dependent: :destroy
  has_many :announcements, foreign_key: 'published_by_id', dependent: :destroy

  validates :name, presence: true
end

end
