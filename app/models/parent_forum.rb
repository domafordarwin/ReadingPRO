# frozen_string_literal: true

class ParentForum < ApplicationRecord
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  has_many :parent_forum_comments, dependent: :destroy

  CATEGORY_LABELS = {
    'general' => '일반',
    'question' => '질문',
    'information' => '정보 공유',
    'discussion' => '토론',
    'other' => '기타'
  }.freeze

  STATUS_LABELS = {
    'open' => '진행중',
    'answered' => '답변완료',
    'closed' => '마감'
  }.freeze

  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORY_LABELS.keys }
  validates :status, presence: true, inclusion: { in: STATUS_LABELS.keys }

  scope :recent, -> { order(created_at: :desc) }
  scope :open_posts, -> { where(status: 'open') }
  scope :answered_posts, -> { where(status: ['answered', 'closed']) }
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

  def closed?
    status == 'closed'
  end

  def answered?
    status == 'answered'
  end

  def open?
    status == 'open'
  end

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def views_count
    view_count || 0
  end

  def comments_count
    parent_forum_comments.count
  end

  def last_activity_at
    [updated_at, parent_forum_comments.maximum(:created_at)].compact.max
  end

  def can_edit?(user)
    return false if user.nil?
    created_by_id == user.id || user.admin?
  end

  def can_reply?(user)
    return false if user.nil?
    return false if closed?
    true
  end
end
