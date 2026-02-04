# frozen_string_literal: true

class ConsultationPost < ApplicationRecord
  belongs_to :student
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  has_many :consultation_comments, dependent: :destroy

  CATEGORY_LABELS = {
    "academic" => "학업 관련",
    "behavior" => "행동/태도",
    "social" => "사회성",
    "health" => "건강",
    "other" => "기타"
  }.freeze

  validates :title, presence: true
  validates :content, presence: true
  validates :category, presence: true, inclusion: { in: %w[academic behavior social health other] }
  validates :visibility, presence: true, inclusion: { in: %w[private public] }
  validates :status, presence: true, inclusion: { in: %w[open answered closed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :open_posts, -> { where(status: "open") }
  scope :answered_posts, -> { where(status: [ "answered", "closed" ]) }
  scope :private_posts, -> { where(visibility: "private") }
  scope :public_posts, -> { where(visibility: "public") }
  scope :search, ->(query) { where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%") }
  scope :by_category, ->(cat) { where(category: cat) }

  def increment_views!
    update(view_count: (view_count || 0) + 1)
  end

  def mark_as_closed!
    update(status: "closed")
  end

  def reopen!
    update(status: "open")
  end

  def visible_to?(user)
    return true if visibility == "public"
    return true if created_by_id == user.id
    return true if user.admin?
    return true if user.teacher? || user.diagnostic_teacher?
    false
  end

  def closed?
    status == "closed"
  end

  def answered?
    status == "answered"
  end

  # 카테고리 라벨 (한글)
  def category_label
    CATEGORY_LABELS[category] || category
  end

  # 교사 답변 여부 확인
  def has_teacher_reply?
    consultation_comments.joins(:created_by).where(users: { role: %w[teacher diagnostic_teacher admin] }).exists?
  end

  # 조회수 (view_count 별칭)
  def views_count
    view_count || 0
  end

  # 마지막 활동 시간 (댓글 또는 게시글 업데이트)
  def last_activity_at
    [ updated_at, consultation_comments.maximum(:created_at) ].compact.max
  end

  # 비공개 여부
  def private?
    visibility == "private"
  end

  # 열림 상태 확인
  def open?
    status == "open"
  end

  # 댓글 작성 가능 여부 (마감되지 않았고 글 작성자, 교사, 관리자 허용)
  def can_reply?(user)
    return false if user.nil?
    return false if closed?
    return true if created_by_id == user.id
    return true if user.admin?
    return true if user.teacher? || user.diagnostic_teacher?
    false
  end
end
