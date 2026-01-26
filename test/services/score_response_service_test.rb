require "test_helper"

class ScoreResponseServiceTest < ActiveSupport::TestCase
  test "scores mcq response and stores metadata" do
    item = Item.create!(
      code: "ITEM-M-1",
      item_type: "mcq",
      status: "draft",
      prompt: "Prompt"
    )
    choice = ItemChoice.create!(item: item, choice_no: 1, content: "Choice A")
    ChoiceScore.create!(item_choice: choice, score_percent: 80, is_key: true)
    form = Form.create!(title: "Form", status: "active")
    FormItem.create!(form: form, item: item, position: 1, points: 10, required: true)
    attempt = Attempt.create!(form: form)
    response = Response.create!(attempt: attempt, item: item, selected_choice: choice)

    ScoreResponseService.call(response.id)
    response.reload

    assert_equal BigDecimal("8"), response.raw_score
    assert_equal BigDecimal("10"), response.max_score
    assert_equal "mcq_auto", response.scoring_meta["mode"]
    assert_equal 80, response.scoring_meta["score_percent"]
    assert_equal 1, response.scoring_meta["choice_no"]
    assert_equal true, response.scoring_meta["is_key"]
  end

  test "raises when choice score is missing" do
    item = Item.create!(
      code: "ITEM-M-2",
      item_type: "mcq",
      status: "draft",
      prompt: "Prompt"
    )
    choice = ItemChoice.create!(item: item, choice_no: 1, content: "Choice A")
    response = Response.create!(attempt: Attempt.create!, item: item, selected_choice: choice)

    assert_raises(ScoreResponseService::Error) do
      ScoreResponseService.call(response.id)
    end
  end

  test "scores constructed response and stores metadata" do
    item = Item.create!(
      code: "ITEM-C-1",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    rubric = Rubric.create!(item: item, title: "Rubric")
    criterion_one = RubricCriterion.create!(rubric: rubric, name: "Content", position: 1)
    criterion_two = RubricCriterion.create!(rubric: rubric, name: "Structure", position: 2)
    form = Form.create!(title: "Form", status: "active")
    FormItem.create!(form: form, item: item, position: 1, points: 6, required: true)
    attempt = Attempt.create!(form: form)
    response = Response.create!(attempt: attempt, item: item)
    ResponseRubricScore.create!(response: response, rubric_criterion: criterion_one, level_score: 2)
    ResponseRubricScore.create!(response: response, rubric_criterion: criterion_two, level_score: 3)

    ScoreResponseService.call(response.id)
    response.reload

    assert_equal BigDecimal("5"), response.raw_score
    assert_equal BigDecimal("6"), response.max_score
    assert_equal "rubric_weighted", response.scoring_meta["mode"]
    assert_equal 2, response.scoring_meta["criteria_count"]
    assert_equal 5, response.scoring_meta["level_sum"]
    assert_equal 6, response.scoring_meta["max_level_sum"]
  end

  test "raises when rubric is missing" do
    item = Item.create!(
      code: "ITEM-C-2",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    response = Response.create!(attempt: Attempt.create!, item: item)

    assert_raises(ScoreResponseService::Error) do
      ScoreResponseService.call(response.id)
    end
  end

  test "raises when rubric criteria are missing" do
    item = Item.create!(
      code: "ITEM-C-3",
      item_type: "constructed",
      status: "draft",
      prompt: "Prompt"
    )
    Rubric.create!(item: item, title: "Rubric")
    response = Response.create!(attempt: Attempt.create!, item: item)

    assert_raises(ScoreResponseService::Error) do
      ScoreResponseService.call(response.id)
    end
  end

  test "handles missing form item points" do
    item = Item.create!(
      code: "ITEM-M-3",
      item_type: "mcq",
      status: "draft",
      prompt: "Prompt"
    )
    choice = ItemChoice.create!(item: item, choice_no: 1, content: "Choice A")
    ChoiceScore.create!(item_choice: choice, score_percent: 50, is_key: false)
    response = Response.create!(attempt: Attempt.create!, item: item, selected_choice: choice)

    ScoreResponseService.call(response.id)
    response.reload

    assert_equal BigDecimal("0"), response.raw_score
    assert_equal BigDecimal("0"), response.max_score
    assert_equal true, response.scoring_meta["points_missing"]
  end
end
