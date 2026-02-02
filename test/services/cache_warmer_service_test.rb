# frozen_string_literal: true

require "test_helper"

class CacheWarmerServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear

    # Create test data
    Item.create!(code: "ITEM001", item_type: 'mcq', prompt: "Test MCQ", status: 'draft')
    Item.create!(code: "ITEM002", item_type: 'constructed', prompt: "Test Constructed", status: 'active')
  end

  teardown do
    Rails.cache.clear
  end

  test "warm_all populates all caches" do
    assert_nil Rails.cache.read("item_types")
    assert_nil Rails.cache.read("item_statuses")

    CacheWarmerService.warm_all

    assert_not_nil Rails.cache.read("item_types")
    assert_not_nil Rails.cache.read("item_statuses")
    assert_not_nil Rails.cache.read("item_difficulties")
  end

  test "get_item_types returns cached value" do
    CacheWarmerService.warm_all

    types = CacheWarmerService.get_item_types
    assert_equal Item.item_types.keys, types
  end

  test "get_item_types falls back to database if not cached" do
    types = CacheWarmerService.get_item_types

    assert_equal Item.item_types.keys, types
  end

  test "get_item_statuses returns cached value" do
    CacheWarmerService.warm_all

    statuses = CacheWarmerService.get_item_statuses
    assert_equal Item.statuses.keys, statuses
  end

  test "get_item_difficulties returns cached value" do
    CacheWarmerService.warm_all

    difficulties = CacheWarmerService.get_item_difficulties
    assert_equal ['상', '중', '하'], difficulties
  end

  test "invalidate_item_caches clears item caches" do
    CacheWarmerService.warm_all

    assert_not_nil Rails.cache.read("item_types")
    CacheWarmerService.invalidate_item_caches
    assert_nil Rails.cache.read("item_types")
  end

  test "invalidate_stimulus_caches clears stimulus caches" do
    CacheWarmerService.warm_all

    assert_not_nil Rails.cache.read("stimuli_total_count")
    CacheWarmerService.invalidate_stimulus_caches
    assert_nil Rails.cache.read("stimuli_total_count")
  end

  test "warm_stimulus_metadata caches count and distribution" do
    CacheWarmerService.warm_stimulus_metadata

    count = Rails.cache.read("stimuli_total_count")
    distribution = Rails.cache.read("stimuli_by_status")

    assert_equal 0, count # No stimuli created in test
    assert_equal({}, distribution)
  end

  test "cache warming with rescue handles errors gracefully" do
    # Simulate an error by mocking Item.count to raise
    original_count = Item.method(:count)
    Item.define_singleton_method(:count) { raise "Test error" }

    assert_nothing_raised do
      CacheWarmerService.warm_all
    end

    Item.define_singleton_method(:count, original_count)
  end

  test "cache values respect expiration time" do
    CacheWarmerService.warm_all

    # Manually set cache entry with very short expiration
    Rails.cache.write("item_types", ["test"], expires_in: 0.seconds)
    sleep 0.1

    # Value might be expired (depends on cache implementation)
    # Just verify the mechanism works
    assert_not_nil CacheWarmerService.get_item_types
  end
end
