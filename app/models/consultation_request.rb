# frozen_string_literal: true

class ConsultationRequest < ApplicationRecord
  # Constants
  CATEGORIES = %w[assessment reading_guidance learning_habits diagnostic other].freeze
  STATUSES = %w[pending approved rejected completed].freeze

  CATEGORY_LABELS = {
    'assessment' => '진단 결과 상담',
    'reading_guidance' => '독서 지도 상담',
    'learning_habits' => '학습 습관 상담',
    'diagnostic' => '진단 해석 상담',
    'other' => '기타'
  }.freeze

  STATUS_LABELS = {
    'pending' => '대기 중',
    'approved' => '승인됨',
    'rejected' => '거절됨',
    'completed' => '완료됨'
  }.freeze

  # Associations
  belongs_to :user, class_name: "User"
  belongs_to :student
  has_many :consultation_request_responses, dependent: :destroy

  # Validations
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :scheduled_at, presence: true
  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :scheduled_at_cannot_be_in_past
  validate :student_is_child_of_user

  # Callbacks
  before_validation :set_initial_status, on: :create
  after_create :create_notification_for_teacher
  after_update :create_status_change_notification, if: :status_changed?

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_student, ->(student_id) { where(student_id: student_id) if student_id.present? }
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :completed, -> { where(status: 'completed') }

  # Instance methods
  def category_label
    CATEGORY_LABELS[category] || category
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def pending?
    status == 'pending'
  end

  def approved?
    status == 'approved'
  end

  def rejected?
    status == 'rejected'
  end

  def completed?
    status == 'completed'
  end

  def approve!
    update(status: 'approved')
  end

  def reject!
    update(status: 'rejected')
  end

  def complete!
    update(status: 'completed')
  end

  private

  def set_initial_status
    self.status ||= 'pending'
  end

  def scheduled_at_cannot_be_in_past
    return if scheduled_at.blank?

    if scheduled_at < Time.current
      errors.add(:scheduled_at, "은(는) 현재 시간 이후여야 합니다")
    end
  end

  def student_is_child_of_user
    return if user.blank? || student.blank?

    unless user.students.include?(student)
      errors.add(:student, "은(는) 본인의 자녀가 아닙니다")
    end
  end

  def create_notification_for_teacher
    # 모든 진단담당교사에게 알림 생성
    User.where(role: 'diagnostic_teacher').each do |teacher|
      Notification.create!(
        user: teacher,
        notification_type: 'consultation_request_created',
        notifiable: self,
        message: "#{student.name} 학생 상담 신청: #{category_label} (#{scheduled_at.strftime('%Y-%m-%d %H:%M')})"
      )
    end
  end

  def create_status_change_notification
    # 상담 신청자(학부모)에게 알림 생성
    if status == 'approved'
      Notification.create!(
        user: user,
        notification_type: 'consultation_request_approved',
        notifiable: self,
        message: "#{student.name} 학생 상담 신청이 승인되었습니다."
      )
    elsif status == 'rejected'
      Notification.create!(
        user: user,
        notification_type: 'consultation_request_rejected',
        notifiable: self,
        message: "#{student.name} 학생 상담 신청이 거절되었습니다."
      )
    end
  end
end
