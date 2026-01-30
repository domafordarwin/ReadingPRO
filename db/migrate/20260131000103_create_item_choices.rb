# frozen_string_literal: true

class CreateItemChoices < ActiveRecord::Migration[8.1]
  def change
    create_table :item_choices do |t|
      t.references :item, null: false, foreign_key: true
      t.integer :choice_no, null: false
      t.text :content, null: false
      t.boolean :is_correct, null: false, default: false
      t.timestamps
    end

    add_index :item_choices, [:item_id, :choice_no], unique: true
  end
end
