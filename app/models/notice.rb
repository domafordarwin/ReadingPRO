# frozen_string_literal: true

class Notice < ApplicationRecord
  # 관계 설정
  belongs_to :created_by, class_name: "User", optional: true

  # 검증
  validates :title, presence: true
  validates :content, presence: true
  validate :target_roles_not_empty

  # 스코프
  scope :active, -> { where("published_at <= ? AND (expires_at IS NULL OR expires_at > ?)", Time.current, Time.current) }
  scope :important, -> { where(important: true) }
  scope :for_role, ->(role) { where("? = ANY(target_roles)", role) }
  scope :recent, -> { order(published_at: :desc) }

  # 역할 상수
  TARGET_ROLES = User::ROLES.freeze

  # 활성 공지사항 여부
  def active?
    published_at <= Time.current && (expires_at.nil? || expires_at > Time.current)
  end

  # 대상 역할 레이블 반환
  def target_roles_labels
    return [] if target_roles.blank?

    role_map = {
      "admin" => "관리자",
      "teacher" => "진단담당교사",
      "parent" => "학부모",
      "student" => "학생"
    }

    target_roles.map { |role| role_map[role] || role }
  end

  private

  def target_roles_not_empty
    if target_roles.blank? || target_roles.empty?
      errors.add(:target_roles, "최소 하나 이상의 대상 역할을 선택해야 합니다")
    end
  end
end
