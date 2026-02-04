class CreateEvaluationIndicators < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_indicators do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :evaluation_indicators, :name, unique: true

    create_table :sub_indicators do |t|
      t.references :evaluation_indicator, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :sub_indicators, [ :evaluation_indicator_id, :name ], unique: true
  end
end
