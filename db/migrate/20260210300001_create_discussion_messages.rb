# frozen_string_literal: true

class CreateDiscussionMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :discussion_messages do |t|
      t.references :questioning_session, null: false, foreign_key: true
      t.integer :stage, null: false, default: 2
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :metadata, default: {}
      t.integer :turn_number, null: false, default: 1
      t.timestamps
    end

    add_index :discussion_messages, %i[questioning_session_id stage turn_number],
              name: "idx_discussion_messages_session_stage_turn"
  end
end
