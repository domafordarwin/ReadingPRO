require "test_helper"

class RubricLevelTest < ActiveSupport::TestCase
  def setup
    item = Item.create!(
      code: "ITEM-CR-3",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    rubric = Rubric.create!(item: item, title: "Rubric")
    @criterion = RubricCriterion.create!(rubric: rubric, name: "Accuracy", position: 1)
  end

  test "validates level_score range" do
    level = RubricLevel.new(rubric_criterion: @criterion, level_score: -1)
    assert_not level.valid?
    assert level.errors[:level_score].present?

    level.level_score = 0
    assert level.valid?

    level.level_score = 3
    assert level.valid?

    level.level_score = 4
    assert_not level.valid?
  end
end
