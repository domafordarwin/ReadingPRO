# frozen_string_literal: true

class Report < ApplicationRecord
  STATUSES = %w[draft generated published].freeze

  belongs_to :attempt

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :attempt_id, uniqueness: true

  scope :drafts, -> { where(status: "draft") }
  scope :generated, -> { where(status: "generated") }
  scope :published, -> { where(status: "published") }

  def draft?
    status == "draft"
  end

  def generated?
    status == "generated"
  end

  def published?
    status == "published"
  end

  def generate!
    update!(status: "generated", generated_at: Time.current)
  end

  def publish!
    update!(status: "published")
  end

  def increment_version!
    update!(version: version + 1)
  end
end
