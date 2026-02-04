# frozen_string_literal: true

require "test_helper"

class KeysetPaginationServiceTest < ActiveSupport::TestCase
  setup do
    # Create test items for pagination testing
    10.times do |i|
      Item.create!(
        code: "ITEM#{i.to_s.rjust(3, '0')}",
        item_type: "mcq",
        prompt: "Test prompt #{i}",
        created_at: Time.current - (10 - i).days
      )
    end

    @relation = Item.all.order(created_at: :desc, id: :desc)
    @service = KeysetPaginationService.new(@relation, per_page: 3)
  end

  test "fetches first page without cursor" do
    result = @service.fetch_page(cursor: nil, direction: "forward")

    assert_equal 3, result[:items].count
    assert result[:has_next]
    assert_not result[:has_prev]
    assert_not_nil result[:next_cursor]
    assert_nil result[:prev_cursor]
  end

  test "fetches next page with cursor" do
    # First page
    first_page = @service.fetch_page(cursor: nil, direction: "forward")
    first_items = first_page[:items]

    # Second page
    second_page = @service.fetch_page(cursor: first_page[:next_cursor], direction: "forward")
    second_items = second_page[:items]

    # Items should be different
    assert_not_equal first_items.map(&:id).sort, second_items.map(&:id).sort
    assert_equal 3, second_items.count
  end

  test "cursor encoding and decoding" do
    item = Item.first
    cursor = @service.send(:encode_cursor, item, "forward")

    assert_not_nil cursor
    decoded = @service.send(:decode_cursor, cursor)

    assert_equal item.id, decoded[:id]
    assert_equal item.created_at.to_i, decoded[:created_at]
    assert_equal "forward", decoded[:type]
  end

  test "backward pagination works" do
    # Get first page
    first_page = @service.fetch_page(cursor: nil, direction: "forward")

    # Go forward
    second_page = @service.fetch_page(cursor: first_page[:next_cursor], direction: "forward")

    # Go backward
    back_page = @service.fetch_page(cursor: second_page[:prev_cursor], direction: "backward")

    # Should be back at first page
    assert_equal first_page[:items].map(&:id).sort, back_page[:items].map(&:id).sort
  end

  test "handles invalid cursor gracefully" do
    result = @service.fetch_page(cursor: "invalid_cursor", direction: "forward")

    # Should return all items when cursor is invalid
    assert_equal 3, result[:items].count
  end

  test "pagination params generation" do
    cursor = "test_cursor"
    base_params = { search: "test" }

    params = @service.pagination_params(cursor, "forward", base_params)
    assert_equal "test_cursor", params[:cursor]
    assert_nil params[:direction] # Default direction not included

    params = @service.pagination_params(cursor, "backward", base_params)
    assert_equal "backward", params[:direction]
  end

  test "detects last page correctly" do
    # Fetch pages until no next
    current_cursor = nil
    page_count = 0
    has_next = true

    while has_next && page_count < 20
      result = @service.fetch_page(cursor: current_cursor, direction: "forward")
      page_count += 1
      has_next = result[:has_next]
      current_cursor = result[:next_cursor]
    end

    # Should have exactly 4 pages (10 items / 3 per page = 3.33 -> 4 pages)
    assert_equal 4, page_count
    assert_not has_next
  end
end
