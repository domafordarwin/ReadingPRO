# frozen_string_literal: true

class Announcement < ApplicationRecord
class Announcement < ApplicationRecord
  belongs_to :teacher, foreign_key: 'published_by_id', optional: true

  enum :priority, { low: 'low', medium: 'medium', high: 'high' }

  validates :title, presence: true
  validates :content, presence: true
end

end
