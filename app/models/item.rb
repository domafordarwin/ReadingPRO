class Item < ApplicationRecord
  belongs_to :stimulus, class_name: "ReadingStimulus", optional: true, inverse_of: :items
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true

  has_many :item_sample_answers, dependent: :destroy
  has_one :rubric, dependent: :destroy
  has_many :item_choices, dependent: :destroy
  has_many :choice_scores, through: :item_choices
  has_many :form_items, dependent: :destroy
  has_many :forms, through: :form_items
  has_many :attempt_items, dependent: :destroy
  has_many :responses, dependent: :destroy

  enum :item_type, { mcq: "mcq", constructed: "constructed" }
  enum :status, { draft: "draft", active: "active", retired: "retired" }
  enum :difficulty, { very_low: "very_low", low: "low", medium: "medium", high: "high", very_high: "very_high" }

  validates :code, presence: true, uniqueness: true
  validates :item_type, presence: true, inclusion: { in: item_types.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :difficulty, presence: true, inclusion: { in: difficulties.keys }
  validates :prompt, presence: true
end
