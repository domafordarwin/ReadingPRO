class ReaderTendency < ApplicationRecord
  belongs_to :attempt
  belongs_to :reader_type, optional: true

  validates :attempt_id, uniqueness: true
end
