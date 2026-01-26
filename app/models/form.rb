class Form < ApplicationRecord
  has_many :form_items
  has_many :items, through: :form_items
  has_many :attempts

  enum :status, { draft: "draft", active: "active" }

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
end
