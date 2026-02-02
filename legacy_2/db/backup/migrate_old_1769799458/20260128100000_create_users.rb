# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :role, null: false
      t.string :email
      t.string :name

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_check_constraint :users, "role IN ('admin', 'teacher', 'parent', 'student')", name: "users_role_check"
  end
end
