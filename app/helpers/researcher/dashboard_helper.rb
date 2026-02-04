# frozen_string_literal: true

module Researcher
  module DashboardHelper
    # Convert bundle status to Korean label
    def status_label(status)
      {
        "draft" => "작업중",
        "active" => "배포가능",
        "archived" => "보관됨"
      }[status] || status
    end

    # Convert difficulty level to Korean label
    def difficulty_label(level)
      {
        "easy" => "쉬움",
        "medium" => "보통",
        "hard" => "어려움"
      }[level] || level
    end

    # Get CSS class for bundle status badge
    def status_badge_class(status)
      "badge-#{status}"
    end

    # Get CSS class for difficulty badge
    def difficulty_badge_class(level)
      "difficulty-#{level}"
    end
  end
end
