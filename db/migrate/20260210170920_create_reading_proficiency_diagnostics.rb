class CreateReadingProficiencyDiagnostics < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_proficiency_diagnostics do |t|
      t.string  :name, null: false
      t.integer :year, null: false
      t.string  :level, null: false
      t.text    :description
      t.string  :status, null: false, default: "draft"
      t.integer :item_count, null: false, default: 0
      t.references :created_by, foreign_key: { to_table: :teachers }, null: true
      t.timestamps
    end

    add_index :reading_proficiency_diagnostics, [:year, :level]
    add_index :reading_proficiency_diagnostics, :status
  end
end
