class AddIndicatorReferencesToItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :items, :evaluation_indicator, foreign_key: true
    add_reference :items, :sub_indicator, foreign_key: true
  end
end
