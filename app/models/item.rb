class Item < ApplicationRecord
  belongs_to :stimulus, optional: true
  has_many :item_sample_answers
  has_one :rubric
  has_many :item_choices
  has_many :choice_scores, through: :item_choices
  has_many :form_items
  has_many :forms, through: :form_items
  has_many :responses

  enum :item_type, { mcq: "mcq", constructed: "constructed" }
  enum :status, { draft: "draft", active: "active", retired: "retired" }

  validates :code, presence: true, uniqueness: true
  validates :item_type, presence: true, inclusion: { in: item_types.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :prompt, presence: true
end
