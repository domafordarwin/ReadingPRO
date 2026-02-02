class CreateSubIndicators < ActiveRecord::Migration[8.1]
  def change
    create_table :sub_indicators, if_not_exists: true do |t|
      t.references :evaluation_indicator,
                   null: false,
                   foreign_key: { on_delete: :cascade },
                   if_not_exists: true
      t.string :code
      t.text :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :sub_indicators, :evaluation_indicator_id, if_not_exists: true
    add_index :sub_indicators, :code, if_not_exists: true
    add_index :sub_indicators,
              [:evaluation_indicator_id, :code],
              unique: true,
              if_not_exists: true
  end
end
