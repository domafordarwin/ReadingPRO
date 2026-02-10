# frozen_string_literal: true

class CreateQuestioningReports < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_reports do |t|
      t.references :questioning_session, null: false, foreign_key: true, index: { unique: true }
      t.references :generated_by, foreign_key: { to_table: :users }, null: true
      t.jsonb :report_sections, default: {}
      t.string :report_status, default: "draft", null: false
      t.text :overall_summary
      t.string :literacy_level
      t.datetime :published_at
      t.timestamps
    end
  end
end
