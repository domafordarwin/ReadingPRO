# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :resource_type, null: false
      t.bigint :resource_id
      t.jsonb :changes, null: false, default: {}
      t.timestamps
    end

    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, :action
  end
end
