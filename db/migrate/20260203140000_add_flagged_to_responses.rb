# frozen_string_literal: true

class AddFlaggedToResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :responses, :flagged_for_review, :boolean, default: false, null: false
    add_index :responses, :flagged_for_review
  end
end
