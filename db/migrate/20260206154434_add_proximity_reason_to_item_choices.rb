class AddProximityReasonToItemChoices < ActiveRecord::Migration[8.1]
  def change
    add_column :item_choices, :proximity_reason, :text
  end
end
