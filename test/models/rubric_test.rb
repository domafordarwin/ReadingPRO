require "test_helper"

class RubricTest < ActiveSupport::TestCase
  test "enforces one rubric per item" do
    item = Item.create!(
      code: "ITEM-CR-1",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    Rubric.create!(item: item, title: "Primary")

    duplicate = Rubric.new(item: item, title: "Duplicate")
    assert_not duplicate.valid?
    assert duplicate.errors[:item_id].present?
  end
end
