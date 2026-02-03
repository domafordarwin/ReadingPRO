# frozen_string_literal: true

class CreateErrorLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :error_logs do |t|
      t.string :error_type, null: false
      t.text :message, null: false
      t.text :backtrace
      t.string :page_path
      t.string :http_method
      t.string :user_agent
      t.string :ip_address
      t.jsonb :params, default: {}
      t.boolean :resolved, default: false

      t.timestamps
    end

    add_index :error_logs, :error_type
    add_index :error_logs, :page_path
    add_index :error_logs, :resolved
    add_index :error_logs, :created_at
  end
end
