# frozen_string_literal: true

class ParentForumComment < ApplicationRecord
  belongs_to :parent_forum
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'

  validates :content, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(created_at: :asc) }

  after_create :update_forum_status

  def can_edit?(user)
    return false if user.nil?
    created_by_id == user.id || user.admin?
  end

  def can_delete?(user)
    return false if user.nil?
    created_by_id == user.id || user.admin?
  end

  private

  def update_forum_status
    # 답변이 달리면 상태를 answered로 변경
    if parent_forum.open?
      parent_forum.update(status: 'answered')
    end
  end
end
