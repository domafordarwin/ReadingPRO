require "test_helper"

class ChoiceScoreTest < ActiveSupport::TestCase
  def setup
    @item = Item.create!(
      code: "ITEM-002",
      item_type: "mcq",
      status: "draft",
      prompt: "Prompt"
    )
    @choice = ItemChoice.create!(item: @item, choice_no: 1, content: "Choice A")
  end

  test "validates score_percent range" do
    score = ChoiceScore.new(item_choice: @choice, score_percent: -1)
    assert_not score.valid?
    assert score.errors[:score_percent].present?

    score.score_percent = 0
    assert score.valid?

    score.score_percent = 100
    assert score.valid?

    score.score_percent = 101
    assert_not score.valid?
  end
end
