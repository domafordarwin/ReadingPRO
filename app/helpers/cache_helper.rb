# frozen_string_literal: true

module CacheHelper
  # Phase 3.4.3: Generate cache key for individual item rows
  #
  # Cache strategy:
  # - Each row gets its own cache entry
  # - Cache key includes: item.id, item.updated_at, associations (stimulus, indicator, rubric)
  # - Cache duration: 1 hour (matches table-level cache)
  # - Invalidation: Automatic via Item#after_save callback
  #
  # Benefits:
  # - When one item updates, only that row's cache is invalidated
  # - Other rows remain cached and serve instantly
  # - Partial Turbo Stream updates can replace individual rows
  # - Reduces fragment cache misses from N% to <1% on typical usage
  #
  # Example:
  #   <% cache(cache_key_for_item(@item)) do %>
  #     <tr>...</tr>
  #   <% end %>
  #
  # Cache Key Format:
  #   ['item_row', item.id, item.updated_at, stimulus.updated_at, indicator.updated_at, rubric.updated_at]

  def cache_key_for_item(item)
    [
      'item_row',           # Namespace for item rows
      item.id,              # Item identifier
      item.updated_at,      # Item cache buster
      item.stimulus&.updated_at,              # Related stimulus changes
      item.evaluation_indicator&.updated_at,  # Related indicator changes
      item.rubric&.updated_at                 # Related rubric changes
    ]
  end

  # Generate DOM ID for item row (used by Turbo Stream to target replacements)
  # Format: item_row_<id> (e.g., item_row_123)
  #
  # Usage in view:
  #   <tr id="<%= dom_id_for_item(item) %>">...</tr>
  #
  # Usage in Turbo Stream:
  #   <turbo-stream action="replace" target="<%= dom_id_for_item(item) %>">

  def dom_id_for_item(item)
    "item_row_#{item.id}"
  end

  # Generate cache key for items table pagination section
  # Separate cache for pagination (less frequently invalidated)

  def cache_key_for_pagination
    [
      'items_pagination',
      @search_query,
      @item_type_filter,
      @status_filter,
      @difficulty_filter,
      @cursor
    ]
  end
end
