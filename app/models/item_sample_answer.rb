class ItemSampleAnswer < ApplicationRecord
  belongs_to :item

  validates :answer, presence: true
end
