class Attempt < ApplicationRecord
  belongs_to :form, optional: true
  belongs_to :student, optional: true
  belongs_to :school_assessment, optional: true
  belongs_to :user, optional: true

  has_many :responses, dependent: :destroy
  has_many :attempt_items, dependent: :destroy
  has_many :items, through: :attempt_items
  has_many :literacy_achievements, dependent: :destroy
  has_one :reader_tendency, dependent: :destroy
  has_one :comprehensive_analysis, dependent: :destroy
  has_many :educational_recommendations, dependent: :destroy
  has_many :guidance_directions, dependent: :destroy
  has_one :report, dependent: :destroy

  enum :status, { in_progress: "in_progress", completed: "completed", pending: "pending" }

  scope :recent, -> { order(created_at: :desc) }

  # Snapshot form items when attempt starts
  def snapshot_form_items!
    AttemptItem.snapshot_from_form(self)
  end
end
