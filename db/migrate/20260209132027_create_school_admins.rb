class CreateSchoolAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :school_admins do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.string :position
      t.timestamps
    end

    add_index :school_admins, [:school_id, :name]
  end
end
