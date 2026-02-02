class CreateEvaluationIndicators < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_indicators, if_not_exists: true do |t|
      t.string :code, null: false
      t.text :name, null: false
      t.text :description
      t.integer :level, default: 1
      t.timestamps
    end

    add_index :evaluation_indicators, :code, unique: true, if_not_exists: true
    add_index :evaluation_indicators, :level, if_not_exists: true
  end
end
