# frozen_string_literal: true

class ParentForum < ApplicationRecord
  # Constants
  CATEGORIES = %w[parenting reading_education learning_tips other].freeze
  STATUSES = %w[open answered closed].freeze

  CATEGORY_LABELS = {
    'parenting' => '자녀지도',
    'reading_education' => '독서교육',
    'learning_tips' => '학습팁',
    'other' => '기타'
  }.freeze

  # Associations
  belongs_to :created_by, class_name: "User"
  has_many :parent_forum_comments, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Callbacks
  before_validation :set_last_activity_at, on: :create
  after_create :update_last_activity
  after_update :update_last_activity, if: :saved_change_to_status?

  # Scopes
  scope :recent, -> { order(last_activity_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :open_posts, -> { where(status: 'open') }
  scope :answered_posts, -> { where(status: 'answered') }
  scope :closed_posts, -> { where(status: 'closed') }
  scope :search, ->(query) {
    if query.present?
      where("title ILIKE :q OR content ILIKE :q", q: "%#{query}%")
    end
  }

  # Instance methods
  def open?
    status == 'open'
  end

  def answered?
    status == 'answered'
  end

  def closed?
    status == 'closed'
  end

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def increment_views!
    increment!(:views_count)
  end

  def mark_as_answered!
    update(status: 'answered', last_activity_at: Time.current)
  end

  def mark_as_closed!
    update(status: 'closed', last_activity_at: Time.current)
  end

  def reopen!
    update(status: 'open', last_activity_at: Time.current)
  end

  def teacher_reply
    if parent_forum_comments.loaded?
      parent_forum_comments.find { |c| c.is_teacher_reply? }
    else
      parent_forum_comments.where(is_teacher_reply: true).order(created_at: :asc).first
    end
  end

  def has_teacher_reply?
    if parent_forum_comments.loaded?
      parent_forum_comments.any?(&:is_teacher_reply?)
    else
      parent_forum_comments.where(is_teacher_reply: true).exists?
    end
  end

  private

  def set_last_activity_at
    self.last_activity_at ||= Time.current
  end

  def update_last_activity
    touch(:last_activity_at)
  end
end
