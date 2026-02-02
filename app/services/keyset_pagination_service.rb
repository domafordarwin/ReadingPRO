# frozen_string_literal: true

class KeysetPaginationService
  # Implements keyset (cursor-based) pagination for efficient large result sets
  #
  # Benefits over offset-based pagination:
  # - O(1) query time regardless of page number (vs O(n) with offset)
  # - No OFFSET scanning required (expensive on large tables)
  # - Better for real-time data (consistent page order even with updates)
  # - Ideal for infinite scroll implementations
  #
  # Usage:
  #   service = KeysetPaginationService.new(Item.order(created_at: :desc, id: :desc), per_page: 25)
  #   result = service.fetch_page(cursor: params[:cursor])
  #   result => { items: [...], next_cursor: "...", prev_cursor: "...", has_next: true }
  #
  # Cursor Format: Base64-encoded JSON
  #   { "type": "forward", "created_at": 1706000000, "id": 123 }
  #   { "type": "backward", "created_at": 1706000000, "id": 123 }

  attr_reader :relation, :per_page, :order_fields

  def initialize(relation, per_page: 25, order_fields: [:created_at, :id])
    @relation = relation
    @per_page = per_page
    @order_fields = order_fields
  end

  # Fetch a page of records using keyset pagination
  # @param cursor [String, nil] - Cursor pointing to the start of the page
  # @param direction [String] - Direction: "forward" (default) or "backward"
  # @return [Hash] - { items, next_cursor, prev_cursor, has_next, has_prev }
  def fetch_page(cursor: nil, direction: "forward")
    # Fetch one extra record to determine if there's a next page
    records = fetch_records(cursor, direction, per_page + 1)

    # Check if there are more records beyond this page
    has_next = records.size > per_page
    has_prev = cursor.present? || direction == "backward"

    # Trim to page size
    items = records.take(per_page)

    # Generate cursors for next/prev navigation
    next_cursor = has_next ? encode_cursor(records[per_page], "forward") : nil
    prev_cursor = items.any? ? encode_cursor(items.first, "backward") : nil

    {
      items: items,
      next_cursor: next_cursor,
      prev_cursor: prev_cursor,
      has_next: has_next,
      has_prev: has_prev
    }
  end

  # Fetch records starting from cursor
  # @private
  def fetch_records(cursor, direction, limit)
    query = @relation.limit(limit)

    if cursor.present?
      decoded = decode_cursor(cursor)
      query = apply_cursor_filter(query, decoded, direction)
    end

    query.to_a
  end

  # Apply cursor filter to the query
  # @private
  def apply_cursor_filter(query, decoded, direction)
    created_at = decoded[:created_at]
    id = decoded[:id]

    if direction == "forward"
      # For forward: get items created BEFORE this cursor (older items)
      query.where(
        "items.created_at < ? OR (items.created_at = ? AND items.id < ?)",
        created_at,
        created_at,
        id
      )
    else
      # For backward: get items created AFTER this cursor (newer items)
      query.where(
        "items.created_at > ? OR (items.created_at = ? AND items.id > ?)",
        created_at,
        created_at,
        id
      ).reorder(created_at: :asc, id: :asc)
    end
  end

  # Encode cursor from a record
  # @private
  def encode_cursor(record, type)
    return nil unless record

    cursor_data = {
      type: type,
      created_at: record.created_at.to_i,
      id: record.id
    }

    Base64.strict_encode64(cursor_data.to_json)
  rescue => e
    Rails.logger.warn("[KeysetPagination] Error encoding cursor: #{e.message}")
    nil
  end

  # Decode cursor string back to hash
  # @private
  def decode_cursor(cursor_string)
    return nil unless cursor_string.present?

    decoded_json = Base64.strict_decode64(cursor_string)
    JSON.parse(decoded_json, symbolize_names: true)
  rescue => e
    Rails.logger.warn("[KeysetPagination] Error decoding cursor: #{e.message}")
    nil
  end

  # Generate URL parameters for pagination links
  # @param cursor [String, nil]
  # @param direction [String]
  # @param base_params [Hash]
  # @return [Hash] - URL parameters
  def pagination_params(cursor, direction, base_params = {})
    params = base_params.dup
    params[:cursor] = cursor
    params[:direction] = direction if direction != "forward"
    params
  end

  # Calculate approximate page number for display purposes
  # Note: This is an estimate and becomes less accurate for later pages
  # Use only for informational purposes (e.g., "Page ~5")
  # @param offset_estimate [Integer] - Estimated number of records before this page
  # @return [Integer]
  def approximate_page_number(offset_estimate = 0)
    (offset_estimate / per_page.to_f).ceil + 1
  end
end
