# frozen_string_literal: true

class Phase31DatabaseOptimization < ActiveRecord::Migration[8.1]
  def change
    # Phase 3.1: Performance optimization for Researcher Portal
    # - Add counter_cache for items count on reading_stimuli
    # - Add indexes for common filter combinations
    # - Add indexes for search fields

    # Add counter_cache column for items.count on reading_stimuli
    # This replaces N+1 queries with single counter
    add_column :reading_stimuli, :items_count, :integer, default: 0, if_not_exists: true

    # Index for evaluation_indicator filtering with status and difficulty
    # Used in: Item Bank filters (status, difficulty, indicator)
    add_index :items, [ :evaluation_indicator_id, :status, :difficulty ],
              name: :idx_items_indicator_status_difficulty, if_not_exists: true

    # Index for sub_indicator filtering
    # Used in: Item Bank sub-indicator filters
    add_index :items, [ :sub_indicator_id, :status ],
              name: :idx_items_sub_indicator_status, if_not_exists: true

    # Index for created_at descending (common sort)
    # Used in: Item Bank sort by recent
    add_index :items, [ :created_at, :id ],
              name: :idx_items_created_at_id, if_not_exists: true

    # Index for search by code (high cardinality)
    # Used in: Item Bank search
    add_index :items, :code,
              name: :idx_items_code_search, if_not_exists: true

    # Index for reading_stimuli search/sort by created_at
    add_index :reading_stimuli, [ :created_at ],
              name: :idx_reading_stimuli_created_at, if_not_exists: true

    # Composite index for status + difficulty (common filter combination)
    add_index :items, [ :status, :difficulty ],
              name: :idx_items_status_difficulty, if_not_exists: true
  end
end
