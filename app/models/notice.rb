class Notice < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  TARGET_ROLES = %w[school_admin teacher student parent].freeze

  validates :title, presence: true
  validates :content, presence: true

  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
  scope :active, -> { where("published_at <= ? AND (expires_at IS NULL OR expires_at > ?)", Time.current, Time.current) }
  scope :important, -> { where(important: true) }
  scope :for_role, ->(role) { where("target_roles @> ARRAY[?]::varchar[]", role) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end
