# frozen_string_literal: true

class AttemptReport < ApplicationRecord
  belongs_to :student_attempt

  enum :performance_level, { advanced: 'advanced', proficient: 'proficient', developing: 'developing', beginning: 'beginning' }

  validates :student_attempt_id, uniqueness: true
end

end
