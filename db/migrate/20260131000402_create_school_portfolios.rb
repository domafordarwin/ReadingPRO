# frozen_string_literal: true

class CreateSchoolPortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :school_portfolios do |t|
      t.references :school, null: false, foreign_key: true
      t.integer :total_students, null: false, default: 0
      t.integer :total_attempts, null: false, default: 0
      t.decimal :average_score, precision: 10, scale: 2
      t.jsonb :difficulty_distribution, null: false, default: {}
      t.jsonb :performance_by_category, null: false, default: {}
      t.datetime :last_updated_at
      t.timestamps
    end

    add_index :school_portfolios, :school_id, unique: true
  end
end
