# frozen_string_literal: true

class Announcement < ApplicationRecord
  # 검증
  validates :content, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true }

  # 스코프
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }

  # 기본값 설정
  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.active = true if active.nil?
    self.display_order ||= (Announcement.maximum(:display_order) || 0) + 1
  end
end
