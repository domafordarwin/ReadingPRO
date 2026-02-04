class AddProximityScoreToItemChoices < ActiveRecord::Migration[8.1]
  def change
    add_column :item_choices, :proximity_score, :integer
  end
end
