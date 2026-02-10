class CreateReadingProficiencyItems < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_proficiency_items do |t|
      t.references :reading_proficiency_diagnostic, null: false, foreign_key: true,
                   index: { name: "idx_rp_items_on_diagnostic_id" }
      t.integer :position, null: false
      t.text    :prompt, null: false
      t.string  :item_type, null: false, default: "mcq"
      t.string  :measurement_factor, null: false
      t.jsonb   :choices, default: []
      t.timestamps
    end

    add_index :reading_proficiency_items,
              [:reading_proficiency_diagnostic_id, :position],
              unique: true, name: "idx_rp_items_on_diag_position"
  end
end
