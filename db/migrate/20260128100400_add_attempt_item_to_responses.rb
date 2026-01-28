# frozen_string_literal: true

class AddAttemptItemToResponses < ActiveRecord::Migration[8.1]
  def change
    add_reference :responses, :attempt_item, foreign_key: { on_delete: :cascade }

    # Partial unique index: when attempt_item_id is present, it must be unique
    add_index :responses, :attempt_item_id,
              unique: true,
              where: "attempt_item_id IS NOT NULL",
              name: "ux_responses_attempt_item"
  end
end
