# frozen_string_literal: true

# Versionable Concern
# Integrates PaperTrail for version tracking
#
# Usage:
#   class MyModel < ApplicationRecord
#     include Versionable
#   end
#
# Requires:
#   - PaperTrail gem installed
#   - ApplicationController setting PaperTrail.request.whodunnit
module Versionable
  extend ActiveSupport::Concern

  included do
    has_paper_trail on: [ :create, :update, :destroy ],
                    ignore: [ :updated_at ],
                    meta: {
                      user_id: :paper_trail_user_id,
                      ip_address: :paper_trail_ip
                    }
  end

  def paper_trail_user_id
    PaperTrail.request.whodunnit
  end

  def paper_trail_ip
    PaperTrail.request.controller_info[:ip] if PaperTrail.request.controller_info
  end

  # Helper methods for accessing versions
  def version_history
    versions.order(created_at: :desc)
  end

  def last_modified_by
    return nil unless versions.exists?
    last_version = versions.order(created_at: :desc).first
    User.find_by(id: last_version.whodunnit) if last_version.whodunnit
  end

  def created_by_user
    return nil unless versions.exists?
    first_version = versions.order(created_at: :asc).first
    User.find_by(id: first_version.whodunnit) if first_version.whodunnit
  end
end
