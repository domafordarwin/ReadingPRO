require "test_helper"

class ResponseTest < ActiveSupport::TestCase
  test "enforces unique item per attempt" do
    item = Item.create!(
      code: "ITEM-R-1",
      item_type: "mcq",
      status: "draft",
      prompt: "Prompt"
    )
    attempt = Attempt.create!
    Response.create!(attempt: attempt, item: item)

    duplicate = Response.new(attempt: attempt, item: item)
    assert_not duplicate.valid?
    assert duplicate.errors[:item_id].present?
  end
end
