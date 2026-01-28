# frozen_string_literal: true

class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :attempt, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :status, null: false, default: "draft"
      t.integer :version, null: false, default: 1
      t.text :artifact_url
      t.datetime :generated_at

      t.timestamps
    end

    add_check_constraint :reports,
                         "status IN ('draft', 'generated', 'published')",
                         name: "reports_status_check"
  end
end
