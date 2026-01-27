class ReadingStimulus < ApplicationRecord
  self.table_name = "stimuli"

  has_many :items, foreign_key: "stimulus_id", inverse_of: :stimulus

  validates :code, uniqueness: true, allow_nil: true
end
