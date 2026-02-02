require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "validates unique code" do
    Item.create!(
      code: "ITEM-001",
      item_type: "mcq",
      status: "draft",
      prompt: "Sample prompt"
    )

    duplicate = Item.new(
      code: "ITEM-001",
      item_type: "mcq",
      status: "draft",
      prompt: "Another prompt"
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:code].present?
  end
end
