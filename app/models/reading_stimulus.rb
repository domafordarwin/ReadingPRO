# frozen_string_literal: true

class ReadingStimulus < ApplicationRecord
class ReadingStimulus < ApplicationRecord
  belongs_to :teacher, foreign_key: 'created_by_id', optional: true
  has_many :items, foreign_key: 'stimulus_id', dependent: :destroy

  validates :body, presence: true
end

end
