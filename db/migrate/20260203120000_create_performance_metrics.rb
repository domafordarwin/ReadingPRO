# frozen_string_literal: true

# Phase 3.5.1: Create PerformanceMetric table for time-series performance data
class CreatePerformanceMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :performance_metrics do |t|
      # Metric identification
      t.string :metric_type, null: false  # 'page_load', 'query_time', 'fcp', etc.
      t.string :endpoint                  # '/researcher/item_bank'
      t.string :http_method               # 'GET', 'POST'

      # Metric values
      t.float :value, null: false         # metric value (ms or percentage)
      t.jsonb :metadata, default: {}      # {user_id, session_id, browser, etc.}

      # Performance context
      t.integer :query_count
      t.float :render_time
      t.float :db_time

      # Web Vitals (from browser)
      t.float :fcp                        # First Contentful Paint
      t.float :lcp                        # Largest Contentful Paint
      t.float :cls                        # Cumulative Layout Shift
      t.float :inp                        # Interaction to Next Paint
      t.float :ttfb                       # Time to First Byte

      t.datetime :recorded_at, null: false, index: true
      t.timestamps
    end

    add_index :performance_metrics, [ :metric_type, :recorded_at ], name: 'idx_performance_metrics_type_time'
    add_index :performance_metrics, [ :endpoint, :recorded_at ], name: 'idx_performance_metrics_endpoint_time'
  end
end
