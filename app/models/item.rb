# frozen_string_literal: true

class Item < ApplicationRecord
  belongs_to :stimulus, class_name: 'ReadingStimulus', foreign_key: 'stimulus_id', optional: true
  belongs_to :teacher, foreign_key: 'created_by_id', optional: true
  has_one :rubric, dependent: :destroy
  has_many :item_choices, dependent: :destroy
  has_many :diagnostic_form_items, dependent: :destroy
  has_many :responses, dependent: :destroy

  enum :item_type, { mcq: 'mcq', constructed: 'constructed' }
  enum :difficulty, { easy: 'easy', medium: 'medium', hard: 'hard' }
  enum :status, { draft: 'draft', active: 'active', archived: 'archived' }

  validates :code, presence: true, uniqueness: true
  validates :item_type, presence: true
  validates :prompt, presence: true

end
