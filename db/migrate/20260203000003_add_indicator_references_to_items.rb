class AddIndicatorReferencesToItems < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:items, :evaluation_indicator_id)
      add_reference :items, :evaluation_indicator,
                    foreign_key: true,
                    null: true,
                    if_not_exists: true
    end

    unless column_exists?(:items, :sub_indicator_id)
      add_reference :items, :sub_indicator,
                    foreign_key: true,
                    null: true,
                    if_not_exists: true
    end

    unless index_exists?(:items, :evaluation_indicator_id)
      add_index :items, :evaluation_indicator_id
    end

    unless index_exists?(:items, :sub_indicator_id)
      add_index :items, :sub_indicator_id
    end

    unless index_exists?(:items, [:evaluation_indicator_id, :sub_indicator_id])
      add_index :items, [:evaluation_indicator_id, :sub_indicator_id]
    end
  end
end
