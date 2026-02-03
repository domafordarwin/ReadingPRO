# frozen_string_literal: true

class ConsultationPost < ApplicationRecord
  belongs_to :student
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  has_many :consultation_comments, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true
  validates :category, presence: true, inclusion: { in: %w[academic behavior social health other] }
  validates :visibility, presence: true, inclusion: { in: %w[private public] }
  validates :status, presence: true, inclusion: { in: %w[open answered closed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :open_posts, -> { where(status: 'open') }
  scope :private_posts, -> { where(visibility: 'private') }
  scope :public_posts, -> { where(visibility: 'public') }
  scope :search, ->(query) { where('title ILIKE ? OR content ILIKE ?', "%#{query}%", "%#{query}%") }
  scope :by_category, ->(cat) { where(category: cat) }

  def increment_views!
    update(view_count: (view_count || 0) + 1)
  end

  def mark_as_closed!
    update(status: 'closed')
  end

  def reopen!
    update(status: 'open')
  end

  def visible_to?(user)
    return true if visibility == 'public'
    return true if created_by_id == user.id
    return true if user.admin?
    return true if user.teacher? || user.diagnostic_teacher?
    false
  end
end
