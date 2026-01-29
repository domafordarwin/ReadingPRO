# frozen_string_literal: true

class ConsultationPost < ApplicationRecord
  # Constants
  CATEGORIES = %w[assessment learning personal technical other].freeze
  VISIBILITIES = %w[private public].freeze
  STATUSES = %w[open answered closed].freeze

  CATEGORY_LABELS = {
    'assessment' => '진단 결과 관련',
    'learning' => '학습 방법',
    'personal' => '개인 상담',
    'technical' => '기술 지원',
    'other' => '기타'
  }.freeze

  # Associations
  belongs_to :student
  belongs_to :created_by, class_name: "User"
  has_many :consultation_comments, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Callbacks
  before_validation :set_last_activity_at, on: :create
  after_create :update_last_activity
  after_update :update_last_activity, if: :saved_change_to_status?

  # Scopes
  scope :recent, -> { order(last_activity_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :by_student, ->(student_id) { where(student_id: student_id) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :public_posts, -> { where(visibility: 'public') }
  scope :private_posts, -> { where(visibility: 'private') }
  scope :open_posts, -> { where(status: 'open') }
  scope :answered_posts, -> { where(status: 'answered') }
  scope :closed_posts, -> { where(status: 'closed') }
  scope :search, ->(query) {
    if query.present?
      where("title ILIKE :q OR content ILIKE :q", q: "%#{query}%")
    end
  }

  # Instance methods
  def private?
    visibility == 'private'
  end

  def public?
    visibility == 'public'
  end

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

  def visible_to?(user)
    return false unless user

    # 부모는 접근 불가
    return false if user.parent?

    # 작성자는 항상 볼 수 있음
    return true if created_by_id == user.id

    # 공개 글은 모든 사용자(학생)가 볼 수 있음
    return true if public?

    # 비공개 글은 진단담당교사만 볼 수 있음
    return true if private? && user.role == 'diagnostic_teacher'

    false
  end

  def can_reply?(user)
    return false unless user

    # 진단담당교사는 항상 답변 가능
    return true if user.role == 'diagnostic_teacher'

    # 공개 글이고 학생인 경우 답변 가능
    return true if public? && user.student?

    # 비공개 글의 작성자는 추가 댓글 가능
    return true if private? && created_by_id == user.id

    false
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
    if consultation_comments.loaded?
      consultation_comments.find { |c| c.is_teacher_reply? }
    else
      consultation_comments.by_teacher.order(created_at: :asc).first
    end
  end

  def has_teacher_reply?
    if consultation_comments.loaded?
      consultation_comments.any?(&:is_teacher_reply?)
    else
      consultation_comments.by_teacher.exists?
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
