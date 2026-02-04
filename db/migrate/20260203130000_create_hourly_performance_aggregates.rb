# frozen_string_literal: true

# Phase 3.5.5: Create Hourly Performance Aggregates Table
#
# Purpose:
# - Store hourly aggregated metrics for efficient historical queries
# - Enables long-term trend analysis
# - Replaces raw metrics after aggregation

class CreateHourlyPerformanceAggregates < ActiveRecord::Migration[8.1]
  def change
    create_table :hourly_performance_aggregates do |t|
      # Identification
      t.string :metric_type, null: false
      t.datetime :hour, null: false

      # Statistics
      t.float :avg_value, null: false
      t.float :p50_value
      t.float :p95_value
      t.float :p99_value
      t.float :min_value
      t.float :max_value
      t.integer :sample_count, null: false

      # Alert tracking
      t.boolean :alert_sent, default: false

      t.timestamps
    end

    # Indexes for efficient querying
    add_index :hourly_performance_aggregates, [ :metric_type, :hour ],
      unique: true, name: 'index_hourly_agg_type_hour'
    add_index :hourly_performance_aggregates, :hour
    add_index :hourly_performance_aggregates, :metric_type
    add_index :hourly_performance_aggregates, [ :metric_type, :alert_sent ]
  end
end
