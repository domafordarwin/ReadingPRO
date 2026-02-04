# frozen_string_literal: true

# Trackable Concern
# Adds creator and updater tracking to models
#
# Usage:
#   class MyModel < ApplicationRecord
#     include Trackable
#   end
#
# Requires:
#   - created_by_id column (bigint, FK to users)
#   - updated_by_id column (bigint, FK to users)
#   - User model
module Trackable
  extend ActiveSupport::Concern

  included do
    belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true
    belongs_to :updater, class_name: "User", foreign_key: "updated_by_id", optional: true

    # Automatically set created_by_id and updated_by_id
    before_validation :set_creator, on: :create
    before_validation :set_updater
  end

  private

  def set_creator
    return if created_by_id.present?
    return unless respond_to?(:created_by_id=)

    user = current_tracking_user
    self.created_by_id = user.id if user
  end

  def set_updater
    return unless respond_to?(:updated_by_id=)

    user = current_tracking_user
    self.updated_by_id = user.id if user
  end

  def current_tracking_user
    Thread.current[:current_user]
  end

  # Class methods
  module ClassMethods
    # Find records created by a specific user
    def created_by(user)
      where(created_by_id: user.id)
    end

    # Find records last updated by a specific user
    def updated_by(user)
      where(updated_by_id: user.id)
    end

    # Find records created or updated by a specific user
    def touched_by(user)
      where("created_by_id = ? OR updated_by_id = ?", user.id, user.id)
    end
  end
end
