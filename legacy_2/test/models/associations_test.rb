require "test_helper"

class AssociationsTest < ActiveSupport::TestCase
  test "item bank associations are wired" do
    assert_equal :has_many, Stimulus.reflect_on_association(:items).macro
    assert_equal :belongs_to, Item.reflect_on_association(:stimulus).macro
    assert_equal :has_many, Item.reflect_on_association(:item_choices).macro
    assert_equal :has_many, Item.reflect_on_association(:choice_scores).macro
    assert_equal :belongs_to, ItemChoice.reflect_on_association(:item).macro
    assert_equal :has_one, ItemChoice.reflect_on_association(:choice_score).macro
    assert_equal :belongs_to, ChoiceScore.reflect_on_association(:item_choice).macro
  end
end
