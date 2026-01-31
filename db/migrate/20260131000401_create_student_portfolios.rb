# frozen_string_literal: true

class CreateStudentPortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :student_portfolios do |t|
      t.references :student, null: false, foreign_key: true, index: { unique: true }
      t.integer :total_attempts, null: false, default: 0
      t.decimal :total_score, precision: 10, scale: 2
      t.decimal :average_score, precision: 10, scale: 2
      t.jsonb :improvement_trend, null: false, default: {}
      t.datetime :last_updated_at
      t.timestamps
    end
  end
end
