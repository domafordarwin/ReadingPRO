# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user

  validates :action, presence: true
  validates :resource_type, presence: true
end
