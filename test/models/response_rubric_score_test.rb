require "test_helper"

class ResponseRubricScoreTest < ActiveSupport::TestCase
  test "enforces unique rubric criterion per response" do
    item = Item.create!(
      code: "ITEM-R-2",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    rubric = Rubric.create!(item: item, title: "Rubric")
    criterion = RubricCriterion.create!(rubric: rubric, name: "Content", position: 1)
    attempt = Attempt.create!
    response = Response.create!(attempt: attempt, item: item)
    ResponseRubricScore.create!(response: response, rubric_criterion: criterion, level_score: 2)

    duplicate = ResponseRubricScore.new(response: response, rubric_criterion: criterion, level_score: 3)
    assert_not duplicate.valid?
    assert duplicate.errors[:rubric_criterion_id].present?
  end
end
