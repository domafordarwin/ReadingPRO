require "test_helper"

class RubricCriterionTest < ActiveSupport::TestCase
  test "enforces unique position per rubric" do
    item = Item.create!(
      code: "ITEM-CR-2",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    rubric = Rubric.create!(item: item, title: "Rubric")
    RubricCriterion.create!(rubric: rubric, name: "Content", position: 1)

    duplicate = RubricCriterion.new(rubric: rubric, name: "Structure", position: 1)
    assert_not duplicate.valid?
    assert duplicate.errors[:position].present?
  end
end
