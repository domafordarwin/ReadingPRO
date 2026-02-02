# frozen_string_literal: true

class CreateParents < ActiveRecord::Migration[8.1]
  def change
    create_table :parents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.timestamps
    end

    add_index :parents, :email
  end
end
