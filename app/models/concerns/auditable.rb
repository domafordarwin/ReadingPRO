# frozen_string_literal: true

# Auditable Concern
# Automatically creates audit log entries for create, update, and destroy actions
#
# Usage:
#   class MyModel < ApplicationRecord
#     include Auditable
#   end
#
# Requires:
#   - AuditLog model
#   - Thread.current[:current_user] set in ApplicationController
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    create_audit_log("create", audit_changes_for_create)
  end

  def log_update
    return if saved_changes.except("updated_at").blank?
    create_audit_log("update", audit_changes_for_update)
  end

  def log_destroy
    create_audit_log("destroy", audit_changes_for_destroy)
  end

  def create_audit_log(action, changes)
    return unless current_audit_user

    AuditLog.create!(
      user_id: current_audit_user.id,
      resource_type: self.class.name,
      resource_id: id,
      action: action,
      changes: changes
    )
  rescue => e
    Rails.logger.error "Failed to create audit log: #{e.message}"
    # Don't raise error - audit logging should not break the main operation
  end

  def current_audit_user
    Thread.current[:current_user]
  end

  def audit_changes_for_create
    {
      created: attributes.except("created_at", "updated_at")
    }
  end

  def audit_changes_for_update
    {
      before: saved_changes.transform_values(&:first),
      after: saved_changes.transform_values(&:last)
    }
  end

  def audit_changes_for_destroy
    {
      deleted: attributes.except("created_at", "updated_at")
    }
  end
end
