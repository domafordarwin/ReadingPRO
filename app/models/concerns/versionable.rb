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
    # Only enable PaperTrail if the gem is loaded
    if defined?(PaperTrail) && respond_to?(:has_paper_trail)
      has_paper_trail on: [ :create, :update, :destroy ],
                      ignore: [ :updated_at ]
    end
  end

  # Helper methods for accessing versions
  def version_history
    return [] unless respond_to?(:versions)
    versions.order(created_at: :desc)
  end

  def last_modified_by
    return nil unless respond_to?(:versions) && versions.exists?
    last_version = versions.order(created_at: :desc).first
    User.find_by(id: last_version.whodunnit) if last_version.whodunnit
  end

  def created_by_user
    return nil unless respond_to?(:versions) && versions.exists?
    first_version = versions.order(created_at: :asc).first
    User.find_by(id: first_version.whodunnit) if first_version.whodunnit
  end
end
