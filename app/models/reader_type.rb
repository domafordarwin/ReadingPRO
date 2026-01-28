class ReaderType < ApplicationRecord
  has_many :reader_tendencies

  validates :code, presence: true, uniqueness: true, length: { is: 1 }
end
